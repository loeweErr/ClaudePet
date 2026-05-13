# Setting up the claude-pet-skins gallery repo

This file mirrors `docs/homebrew-tap/SETUP.md` — a maintainer one-time checklist for spinning up the community-skin gallery repo. Once created, contributors do not repeat these steps.

## 1. Create the repo

```bash
gh repo create loeweErr/claude-pet-skins --public \
  --description "Community palette gallery for ClaudePet" \
  --add-readme
```

Or use the GitHub web UI — the name must be exactly `claude-pet-skins` so the in-app menu link in ClaudePet finds it.

## 2. Copy the skeleton

From this ClaudePet checkout:

```bash
cd /path/to/claude-pet-skins      # the new repo
cp -R /path/to/ClaudePet/docs/community-skins-repo/. .
git add .
git commit -m "Initial gallery skeleton"
git push
```

## 3. Verify CI

Open the Actions tab — the `Validate skins` workflow should pass on the example palette.

## 4. First-batch seeding

To meet the P2-4 acceptance bar (≥5 community skins), seed the gallery yourself:

- Open a few PRs from the same repo (or from a sock-puppet account if you must) introducing tasteful starter palettes — `twilight`, `sakura`, `terminal-amber`, `forest`, `monokai-cat` are likely-popular themes
- Or solicit them publicly: tweet "first 5 skin PRs to claude-pet-skins get featured in the README and a Twitter shout-out"

The example skin in this skeleton can become `twilight`, since the colors already evoke that vibe.

## 5. Wire the in-app menu link

Once the gallery repo is live, the right-click menu's **浏览社区皮肤…** entry in ClaudePet opens this repo's web page. No further code change needed — the URL is `https://github.com/loeweErr/claude-pet-skins`.

## 6. Roadmap (later)

The roadmap mentions "从 GitHub Releases API 拉取列表" — an in-app browser that fetches the gallery index from the API and offers one-click install. That's intentionally deferred to a separate ticket since it needs:

- Network reachability handling
- A pinned releases.json index in this repo (so the app doesn't paginate through GitHub Search)
- A confirmation UX before writing into `~/Library/Application Support/ClaudePet/skins/`

For now, the curl one-liner in this repo's README is the install path.
