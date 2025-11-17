import { Octokit } from "@octokit/rest";
import dotenv from "dotenv";
import { supabase } from "./supabase.js";
import { v4 as uuidv4 } from "uuid";
dotenv.config(); //create a .env file in this same repo

class PrEngine {
  constructor(token) {
    this.token = token;
    this.octokit = new Octokit({
      auth: this.token,
      request: { retries: 2 },
    });

    // === NEW CACHES ===
    this.githubCache = {};
    this.supabaseCache = {};
  }

  // Generic cache wrapper
  async cacheGet(key, cache, fn) {
    if (cache[key]) {
      console.log(`Returning cached: ${key}`);
      return cache[key];
    }
    const result = await fn();
    cache[key] = result;
    return result;
  }

  async safeRequest(fn, retry = 0) {
    try {
      return await fn();
    } catch (err) {
      if (err.status === 403 && retry < 5) {
        const wait = 5000 + retry * 3000;
        console.log(`Rate Limit hit. Waiting for ${wait / 1000}s...`);
        await new Promise((res) => setTimeout(res, wait));
        return this.safeRequest(fn, retry + 1);
      }
      throw err;
    }
  }

  /** ------------------ GITHUB CACHE WRAPPED FUNCTIONS ------------------ */

  async getUser(username) {
    return this.cacheGet(`user:${username}`, this.githubCache, async () =>
      this.safeRequest(() =>
        this.octokit.users.getByUsername({ username }).then((res) => res.data)
      )
    );
  }

  async getRepos(username) {
    return this.cacheGet(`repos:${username}`, this.githubCache, async () =>
      this.safeRequest(() =>
        this.octokit.repos
          .listForUser({ username, per_page: 100 })
          .then((res) => res.data)
      )
    );
  }

  async getPullRequests(username) {
    return this.cacheGet(`prs:${username}`, this.githubCache, async () =>
      this.safeRequest(() =>
        this.octokit.search
          .issuesAndPullRequests({
            q: `author:${username} type:pr`,
            per_page: 50,
          })
          .then((res) => res.data.items)
      )
    );
  }

  async getAllPrs(owner, repo) {
    return this.cacheGet(
      `allprs:${owner}/${repo}`,
      this.githubCache,
      async () => {
        const list = await this.safeRequest(() =>
          this.octokit.pulls.list({
            owner,
            repo,
            state: "all",
            per_page: 100,
          })
        ).then((res) => res.data);

        const full = await Promise.all(
          list.map((pr) =>
            this.safeRequest(() =>
              this.octokit.pulls.get({
                owner,
                repo,
                pull_number: pr.number,
              })
            ).then((res) => res.data)
          )
        );

        return full;
      }
    );
  }

  async getPrByNumber(owner, repo, number) {
    return this.cacheGet(
      `pr:${owner}/${repo}/${number}`,
      this.githubCache,
      async () =>
        this.safeRequest(() =>
          this.octokit.pulls
            .get({
              owner,
              repo,
              pull_number: number,
            })
            .then((res) => res.data)
        )
    );
  }

  async getPrCode(owner, repo, pull_number) {
    return this.cacheGet(
      `prcode:${owner}/${repo}/${pull_number}`,
      this.githubCache,
      async () => {
        const commits = await this.safeRequest(() =>
          this.octokit.pulls.listCommits({
            owner,
            repo,
            pull_number,
          })
        ).then((res) => res.data);

        const allFiles = [];

        for (const commit of commits) {
          const commitFiles = await this.safeRequest(() =>
            this.octokit.repos.getCommit({
              owner,
              repo,
              ref: commit.sha,
            })
          ).then((res) => res.data.files);

          for (const file of commitFiles) {
            const codeKey = `raw:${file.raw_url}`;
            const code = await this.cacheGet(
              codeKey,
              this.githubCache,
              async () => {
                const response = await this.safeRequest(() =>
                  fetch(file.raw_url)
                );
                return await response.text();
              }
            );

            allFiles.push({
              filename: file.filename,
              status: file.status,
              sha: commit.sha,
              code,
            });
          }
        }

        return allFiles;
      }
    );
  }

  /** ------------------ SUPABASE CACHE WRAPPED ------------------ */

  async getMemberId(username) {
    return this.cacheGet(`member:${username}`, this.supabaseCache, async () => {
      let { data, error } = await supabase
        .from("member_profiles")
        .select("id")
        .eq("github_username", username)
        .single();

      if (error) {
        console.error("Error checking members", error);
        return null;
      }

      if (!data) return null;

      return data.id;
    });
  }

  async insertContribution(data) {
    const key = `contrib:${data.github_pr_id}`;

    // 1️⃣ CHECK CACHE FIRST
    if (this.supabaseCache[key]) {
      console.log("Returning cached contribution");
      return this.supabaseCache[key];
    }

    // 2️⃣ CHECK SUPABASE BEFORE INSERT
    const { data: existing, error: selectErr } = await supabase
      .from("contributions")
      .select("*")
      .eq("github_pr_id", data.github_pr_id)
      .eq("repo_owner", data.repo_owner)
      .eq("repo_name", data.repo_name)
      .single();

    if (existing) {
      console.log("Contribution already exists → No insert");
      this.supabaseCache[key] = existing; // store in cache
      return existing;
    }

    if (selectErr && selectErr.code !== "PGRST116") {
      console.error("Select error:", selectErr);
    }

    // 3️⃣ INSERT ONLY IF NEW
    const { data: inserted, error: insertErr } = await supabase
      .from("contributions")
      .insert([data])
      .select();

    if (insertErr) {
      console.error("Insert error:", insertErr);
      return null;
    }

    console.log("Inserted new contribution:", inserted[0]);

    // Store in cache
    this.supabaseCache[key] = inserted[0];

    return inserted[0];
  }

  /** ------------------ CONTRIB BUILDER ------------------ */

  calculatePRScore(pr, eventConfig, status) {
    let baseScore = 0;
    switch (status) {
      case "merged":
        baseScore = eventConfig.scoring_rules.pr_merged;
        break;
      case "open":
        baseScore = eventConfig.scoring_rules.pr_opened;
        break;
      case "closed":
        baseScore = eventConfig.scoring_rules.pr_closed_unmerged;
        break;
    }

    const complexity = this.assessComplexity(pr);
    baseScore *= eventConfig.scoring_rules.complexity_multiplier[complexity];

    if (pr.comments) {
      baseScore += eventConfig.scoring_rules.review_addressed;
    }

    return Math.round(baseScore * 100) / 100;
  }

  assessComplexity(pr) {
    const totalLines = pr.additions + pr.deletions;
    const fileCount = pr.changed_files;

    if (totalLines < 50 && fileCount <= 2) return "small";
    if (totalLines < 200 && fileCount <= 5) return "medium";
    return "large";
  }

  async contribTable(pr, repo_owner, repo_name, eventConfig = null) {
    const status = pr.merged_at
      ? "merged"
      : pr.state === "closed"
      ? "closed"
      : "open";

    let score = this.calculatePRScore(pr, eventConfig, status);
    let memberId = await this.getMemberId(pr.user.login);

    let shit = {
      id: uuidv4(),
      member_id: memberId,
      github_pr_id: pr.id,
      repo_name,
      repo_owner,
      pr_number: pr.number,
      pr_title: pr.title,
      pr_link: pr.html_url,
      status,
      author_github_username: pr.user.login,
      created_at: pr.created_at,
      updated_at: pr.updated_at,
      closed_at: pr.closed_at,
      merged_at: pr.merged_at,
      labels: pr.labels.map((l) => l.name),
      reviewers: pr.requested_reviewers.map((r) => r.login),
      reviews_count: 0,
      comments_count: pr.comments,
      additions: pr.additions,
      deletions: pr.deletions,
      changed_files: pr.changed_files,
      score,
      metadata: pr,
      user_code: await this.getPrCode(repo_owner, repo_name, pr.number),
      last_synced: new Date().toISOString(),
    };

    if (memberId) {
      await this.insertContribution(shit);
    }

    return shit;
  }
}

export default PrEngine;
