import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import PrEngine from "./PRTrackingEngine.js";
dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const engine = new PrEngine(process.env.GITHUB_TOKEN);

let eventConfig = {
  id: 1,
  name: "Bug Blitz 2025",
  start_date: "2025-02-01",
  end_date: "2025-02-28",
  scoring_rules: {
    pr_merged: 10,
    pr_opened: 3,
    pr_closed_unmerged: -2,
    review_addressed: 2,
    complexity_multiplier: {
      small: 1,
      medium: 1.5,
      large: 2,
    },
  },
  whitelisted_repos: ["org/project1", "org/project2"],
};

// Health check
app.get("/", (req, res) => res.send("PR tracker online"));

// Fetch PRs by user
app.get("/api/pr/user/:username", async (req, res) => {
  try {
    const { username } = req.params;
    const prs = await engine.getPullRequests(username);
    const safePRs = Array.isArray(prs) ? prs : [];

    res.json({
      success: true,
      count: safePRs.length,
      title: safePRs.map((pr) => pr.title),
      url: safePRs.map((pr) => pr.html_url),
      prs: safePRs,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Fetch all PRs for a repo
app.get("/api/pr/repo/:owner/:repo", async (req, res) => {
  try {
    const { owner, repo } = req.params;
    const prs = await engine.getAllPrs(owner, repo);
    const safePRs = Array.isArray(prs) ? prs : [];

    res.json({
      success: true,
      count: safePRs.length,
      title: safePRs.map((pr) => pr.title),
      url: safePRs.map((pr) => pr.html_url),
      prs: safePRs,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Fetch single PR by number
app.get("/api/pr/repos/:owner/:repo/pulls/:number", async (req, res) => {
  try {
    const { owner, repo, number } = req.params;
    const pr = await engine.getPrByNumber(owner, repo, Number(number));
    res.json({ success: true, pr });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Fetch all PRs with contribution details (scoring etc.)
app.get("/api/pr/everything/:owner/:repo", async (req, res) => {
  try {
    const { owner, repo } = req.params;
    const prs = await engine.getAllPrs(owner, repo);
    const safePRs = Array.isArray(prs) ? prs : [];

    const rows = await Promise.all(
      safePRs.map(async (pr) => {
        try {
          return await engine.contribTable(pr, owner, repo, eventConfig);
        } catch (err) {
          console.error(
            `Error building contribTable for PR #${pr.number}:`,
            err
          );
          return null;
        }
      })
    );

    res.json({
      success: true,
      row: rows.filter((r) => r !== null),
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
