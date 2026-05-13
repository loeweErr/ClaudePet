# Changelog

All notable changes to ClaudePet land here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Maintainers regenerate this file at every release with:

```bash
git cliff -o CHANGELOG.md
```

## [Unreleased]

### Added

- **Multi-skin system** (palette JSON). Three bundled — `mochi` (orange, default), `shadow` (black, amber eyes), `snow` (white, ice-blue eyes). Community skins drop into `~/Library/Application Support/ClaudePet/skins/<id>/palette.json`. Switch via right-click menu → 切换皮肤.
- **Global hot keys** via Carbon HIToolbox: `⌃⌥⌘P` summon to mouse, `⌃⌥H` hide/show, `⌃⌥F` feed.
- **Launch at login** via SMAppService (macOS 13+).
- **Personality presets** — default / 傲娇 / 粘人 / 老干部 / 二次元 — editable through a right-click → 人格… sheet. Exports to `~/Library/Application Support/ClaudePet/personality.json` for external use (e.g. the WeChat bridge's `CLAUDE_SYSTEM_PROMPT`).
- **Reply char limit** and **TTS toggle** as part of the personality settings.
- **Browse Community Skins** menu link to the [`claude-pet-skins`](https://github.com/loeweErr/claude-pet-skins) gallery.
- **One-click installer** (`install.sh`) that detects toolchain and merges `claude_desktop_config.json` safely.
- **Homebrew cask** at `loeweErr/tap/claude-pet`.
- **English README** alongside the existing Chinese one.
- **53+ unit tests** covering MoodSystem, PetState, MCP tool catalog, skins, and personality.
- **GitHub Actions CI** on macOS-13 + macOS-14, plus shellcheck on Ubuntu.
- **Release workflow** on `v*` tags — builds `.app`, zips with `ditto`, computes SHA-256, calls `gh release create`.
- **Four starter recipes** (Focus Guard, Calendar Reminder, VIP Email, Git Celebration) under `docs/recipes/`.

### Changed

- `PetState.load()` now migrates forward when a new field lands: missing keys are filled from a fresh default and re-decoded, so existing users keep their bond / days-together across upgrades.

### Docs

- `MIT LICENSE` at repo root.
- `docs/creating-skins.md` — author guide for palette skins.
- `docs/recipes/` — 4 starter recipes with copy-pasteable config.
- `docs/personality.md` — personality presets + the manual WeChat-bridge sync steps.
- `docs/social/` — Twitter / 小红书 / Product Hunt content drafts.
- `docs/homebrew-tap/` — cask template + setup checklist.
- `docs/community-skins-repo/` — full skeleton for the separate skins gallery (schema, validator, CI workflow).
- `docs/rfcs/` — long-term direction notes.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue / PR templates.

## [3.0.0] — Pending first release

ClaudePet v3 was rebuilt as a Claude Desktop MCP plugin. Items listed under **Unreleased** above will roll into the v3.0.0 release notes when the tag is cut.
