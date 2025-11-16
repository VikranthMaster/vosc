import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import PrEngine from "./PRTrackingEngine.js";
dotenv.config({ path: path.resolve("./supabase/.env.example") });

const app = express();
app.use(cors());
app.use(express.json());

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

app.get("/", (req, res) => {
  res.send("PR tracker online");
});

app.get("/api/pr/user/:username", async (req, res) => {
  try {
    const { username } = req.params;
    const engine = new PrEngine(process.env.GITHUB_TOKEN, username);
    const prs = await engine.getPullRequests();

    res.json({
      success: true,
      count: prs.length,
      title: prs.map((pr) => pr.title),
      url: prs.map((pr) => pr.html_url),
      prs,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

app.get("/api/pr/repo/:owner/:repo", async (req, res) => {
  try {
    const { owner, repo } = req.params;
    const engine = new PrEngine(process.env.GITHUB_TOKEN, owner);
    const prs = await engine.getAllPrs(owner, repo);
    res.json({
      success: true,
      count: prs.length,
      title: prs.map((pr) => pr.title),
      url: prs.map((pr) => pr.html_url),
      prs,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

app.get("/api/pr/repos/:owner/:repo/pulls/:number", async (req, res) => {
  try {
    const { owner, repo, number } = req.params;
    const engine = new PrEngine(process.env.GITHUB_TOKEN, owner);
    const prs = await engine.getPrByNumber(owner, repo, number);
    res.json({
      success: true,
      prs,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

app.get("/api/pr/everything/:owner/:repo", async (req, res) => {
  try {
    const { owner, repo } = req.params;
    const engine = new PrEngine(process.env.GITHUB_TOKEN, owner);
    const getprs = await engine.getAllPrs(owner, repo);
    const row = await Promise.all(
      getprs.map((pr) => {
        return engine.contribTable(pr, owner, repo, eventConfig);
      })
    );
    res.json({
      success: true,
      row,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

const PORT = 4000;
app.listen(4000, () => {
  console.log("Server running on port " + PORT);
});
