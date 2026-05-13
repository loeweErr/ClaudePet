# Setting up the Homebrew tap

This file is a one-time setup checklist for the maintainer (`loeweErr`). Once the tap exists, contributors do not need to repeat this.

## 1. Create the tap repo

```bash
gh repo create loeweErr/homebrew-tap --public \
  --description "Homebrew tap for loeweErr's Mac apps (claude-pet)" \
  --add-readme
```

(Or do it via the GitHub web UI — name **must** be `homebrew-tap`; the `homebrew-` prefix is what `brew tap loeweErr/tap` looks for.)

## 2. Lay out the tap

```
homebrew-tap/
└── Casks/
    └── claude-pet.rb   # copied from this directory
```

## 3. Compute the cask SHA-256

After the first ClaudePet release exists at `https://github.com/loeweErr/ClaudePet/releases/tag/v3.0.0`:

```bash
curl -sLO "https://github.com/loeweErr/ClaudePet/releases/download/v3.0.0/ClaudePet-v3.0.0.zip"
shasum -a 256 ClaudePet-v3.0.0.zip
```

Paste the hex digest into the `sha256 "..."` line of `Casks/claude-pet.rb`.

> The release workflow (`.github/workflows/release.yml`) also uploads `ClaudePet-v<version>.zip.sha256` next to the zip — `cat`ing that is the easiest way to grab the digest without redownloading.

## 4. Commit and push

```bash
cd homebrew-tap
git add Casks/claude-pet.rb
git commit -m "Add claude-pet cask v3.0.0"
git push
```

## 5. Verify install

On any clean macOS machine:

```bash
brew tap loeweErr/tap        # registers the tap
brew install --cask claude-pet
```

If the install succeeds, the cask is wired up. The post-install caveat will tell the user how to register the MCP server in Claude Desktop's config.

## 6. Bump on every release

For every new `vX.Y.Z` release of ClaudePet:

1. Update `version "X.Y.Z"` in `Casks/claude-pet.rb`.
2. Update the `sha256` from the new release's `.sha256` asset.
3. Commit, push.

Optional: automate steps 1–3 with a workflow in the tap repo that listens for the `release` event in `loeweErr/ClaudePet`.
