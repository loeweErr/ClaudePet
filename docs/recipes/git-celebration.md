# Recipe: Git Celebration

> When a PR is merged or CI turns green, the cat throws a tiny party.

**Loop**: GitHub event → success detected → `pet_emote sparkle count=20` + `pet_say "merged ✦"` (or `pet_meow` for the bigger ones).

## What you need

- ClaudePet installed
- A GitHub MCP server. The official [`github/github-mcp-server`](https://github.com/github/github-mcp-server) covers PRs, Actions runs, releases.

## Claude Desktop config

```json
{
  "mcpServers": {
    "claude-pet": {
      "command": "/Applications/ClaudePet.app/Contents/MacOS/ClaudePet",
      "args": ["--mcp"]
    },
    "github": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<your PAT>"
      }
    }
  }
}
```

## Trigger phrase

> Every minute, check my open PRs in `loeweErr/ClaudePet`. If any one merges, celebrate with mochi: a long sparkle + a heart + a "merged ✦" bubble. If a CI run on `main` goes red, instead make mochi look concerned with `dust` particles.

Claude will:

1. Poll `github_list_pulls` and `github_list_workflow_runs`
2. Diff against the previous snapshot to detect transitions (open→merged, success→failure)
3. On merge:
   - `pet_say { text: "merged: <PR title>", duration: 4 }`
   - `pet_emote { kind: "sparkle", count: 20 }` (the count maxes at 20 — the cat's "biggest" celebration)
   - `pet_emote { kind: "heart", count: 6 }` chased after a half-second
   - Optional: `pet_meow { text: "ya~ 🎉" }` for releases tagged `v*`
4. On red CI:
   - `pet_say { text: "CI failed on main 😿", duration: 5 }`
   - `pet_emote { kind: "dust", count: 6 }`

## Why it works

Git/CI notifications usually arrive as easily-ignored toasts. Tying the cat's mood to your repo's pulse turns the desktop into a passive ambient awareness display — you feel the project's heartbeat without needing to actively check.

## Variations

- **Per-repo personality**: pet has one mood for `personal/*` repos (calm), another for `work/*` (more sparkles for shipped features)
- **Streak tracking**: Claude keeps a daily PR-merged count and at end-of-day calls `pet_say "今天合了 N 个 PR ✦"`
- **Squad mode**: subscribe to a teammate's repo activity too — the cat reacts to their wins as well as yours
