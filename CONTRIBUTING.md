# Contributing to ClaudePet

Glad you're here. ClaudePet is a small app, and the bar for contributing is intentionally low — read this once and you're ready.

## Quick paths

| What you want to do | Where to go |
|---|---|
| Report a bug | [`bug-report` issue template](.github/ISSUE_TEMPLATE/bug-report.yml) |
| Propose a feature | [`feature-request` template](.github/ISSUE_TEMPLATE/feature-request.yml) |
| Add a skin | [`claude-pet-skins`](https://github.com/loeweErr/claude-pet-skins) (separate repo) |
| Add a recipe | [`new-recipe` template](.github/ISSUE_TEMPLATE/new-recipe.yml) here, then PR a doc into `docs/recipes/` |
| Ask a question | [Discussions](https://github.com/loeweErr/ClaudePet/discussions) |
| Submit a code PR | Read the rest of this file |

## Code contributions

### Local setup

```bash
git clone https://github.com/loeweErr/ClaudePet.git
cd ClaudePet

# Build (full Xcode preferred — needed for `swift test`):
swift build -c release
swift test --parallel

# CommandLineTools-only fallback (no SwiftPM Platforms/):
swiftc -O -target arm64-apple-macos13 \
  -framework AppKit -framework Foundation \
  -o ClaudePet-bin Sources/ClaudePet/*.swift
```

### Style

- Swift idiomatic. Match what's already in the repo — names, file organization, indentation, comment density.
- One concept per file. `MoodSystem.swift`, `SkinManager.swift`, `HotKeyManager.swift` are the pattern.
- Tests live in `Tests/ClaudePetTests/`. If your change has a pure-logic component, add a test for it. The CI matrix on macOS-13/14 runs `swift test --parallel` on every PR.
- Don't add a dependency on a third-party package without raising it in an issue first — ClaudePet ships zero today and that's a feature.
- AppKit / GUI changes are hard for reviewers to verify without running locally. Include a short screen recording or screenshot in the PR.

### State migrations

If you add a field to `PetState`, the existing forward-compat shim in `PetState.load()` will fill defaults for old saves automatically. Don't bump the storage key (`com.claude.pet.state.v2`) — that orphans every user's bond / days-together. If you genuinely need a breaking schema change, raise it in an issue first.

### MCP tool changes

If you add or change a `pet_*` tool:

1. Update `Tools.list` in `MCPServer.swift` (the JSON schema Claude Desktop sees)
2. Update `Tools.names`
3. Handle the method in `PetCoordinator.handleIPC`
4. Update the table in both READMEs (English + Chinese)
5. Add a test in `Tests/ClaudePetTests/MCPToolsTests.swift`

### Commit style

Match the existing log: `<type>(P0-3): short imperative summary`. Types in use: `feat`, `fix`, `docs`, `test`, `ci`, `chore`. Body wraps at ~72.

## Maintainer SLA

These are soft targets — best-effort, not contractual.

- **Issues**: first response within **24 hours** on weekdays
- **Bugs labeled `critical`**: triaged within **48 hours**, fixed within **1 week** if reproducible
- **PRs**: first review within **3 days**
- **Skin PRs in `claude-pet-skins`**: 24 hours (the validator does the heavy lifting)

If you don't hear back, pinging the issue is welcome — maintainers also miss notifications.

## Code of conduct

By participating you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md). Short version: be kind, assume good faith, treat the project like a shared studio rather than a battlefield.

## License

ClaudePet is MIT-licensed. By contributing you agree your contributions are also MIT, unless explicitly noted otherwise in the PR.
