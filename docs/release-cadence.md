# Release cadence

A predictable rhythm makes the project feel alive without burning the maintainer out. Soft targets — adjust as life happens.

## Cadence

| Cadence | What ships | Version bump |
|---|---|---|
| **Monthly** (first Wednesday of the month) | Minor: new skin(s), new animation, new recipe doc, bug fixes | `vX.Y.Z` → `vX.Y+1.0` |
| **Quarterly** (Mar / Jun / Sep / Dec) | Feature: new MCP tool, new menu UI, structural refactor | `vX.Y.Z` → `vX+1.0.0` (if breaking) or `vX.Y+1.0` |
| **As needed** | Critical bug fix | `vX.Y.Z` → `vX.Y.Z+1` |

Skip a month if nothing meaningful changed — silence is fine, faking news is not.

## Release runbook

For a tagged release `vX.Y.Z`:

1. **Update `CHANGELOG.md`**
   ```bash
   git cliff --tag vX.Y.Z -o CHANGELOG.md
   ```
   Manually polish the prose under the new version header — `git-cliff` gives you the skeleton, you give it personality.

2. **Bump any hardcoded versions**
   - `docs/homebrew-tap/Casks/claude-pet.rb` → `version "X.Y.Z"`
   - The Info.plist `CFBundleVersion` is set by `.github/workflows/release.yml` from the tag — no manual edit needed.

3. **Commit the changelog**
   ```bash
   git add CHANGELOG.md docs/homebrew-tap/Casks/claude-pet.rb
   git commit -m "chore: prepare vX.Y.Z release"
   git push
   ```

4. **Tag and push**
   ```bash
   git tag vX.Y.Z
   git push --tags
   ```
   The release workflow runs on macOS-14, builds the `.app`, zips with `ditto`, computes SHA-256, and publishes a GitHub Release with install instructions in the notes.

5. **Update the Homebrew tap**
   - Compute the new SHA-256 (or grab it from the `.sha256` asset uploaded by the workflow)
   - Bump `version` + `sha256` in `loeweErr/homebrew-tap/Casks/claude-pet.rb`
   - Commit + push to the tap repo

6. **Announce**
   - 1 tweet linking the release notes
   - 1 小红书 笔记 (use the templates in `docs/social/`)
   - Optional: edit the README's `As featured in:` line if a notable list picked it up

7. **Open the next milestone**
   - Create a GitHub Milestone for the next release (e.g. `vX.Y+1.0`)
   - Triage issues into it

## What goes in a "minor" vs "feature" release

- **Minor**: anything that doesn't change the `pet_*` tool surface or the PetState schema beyond append-only fields. Adding a 4th built-in skin, a new pose, a recipe doc, a bug fix.
- **Feature**: new `pet_*` tool, new menu / UI surface, new persisted PetState field, change to the MCP protocol version we declare.
- **Breaking**: changing the storage key (`com.claude.pet.state.v2`), removing a `pet_*` tool, changing tool input schemas. Avoid unless absolutely necessary; bump major version.

## Conventional commits

The `cliff.toml` parser expects:

- `feat:` → **Added**
- `fix:` → **Fixed**
- `docs:` → **Docs**
- `test:` → **Tests**
- `ci:` → **CI**
- `chore:` → **Chore**
- `perf:` → **Performance**
- `refactor:` → **Refactor**

Scope hint (`feat(P1-5): ...`) is allowed but optional. Anything that doesn't match a parser falls into `filter_unconventional = true` and is dropped from the changelog — which is fine for trivial edits.
