cask "claude-pet" do
  version "3.0.0"
  # Replace this with the SHA-256 emitted by the release workflow
  # (see ClaudePet-v#{version}.zip.sha256 in the GitHub release assets).
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url      "https://github.com/loeweErr/ClaudePet/releases/download/v#{version}/ClaudePet-v#{version}.zip"
  name     "Claude Pet"
  desc     "Pixel cat that lives on your macOS desktop, controlled by Claude Desktop via MCP"
  homepage "https://github.com/loeweErr/ClaudePet"

  depends_on macos: ">= :ventura"

  app "ClaudePet.app"

  # The MCP server registration is left to the user: rewriting
  # claude_desktop_config.json from a Homebrew postflight is fragile
  # (we'd need to merge JSON safely with whatever the user already has).
  # Show the snippet as a caveat so they can paste it themselves.
  caveats <<~EOS
    To enable ClaudePet inside Claude Desktop, add the following to
    ~/Library/Application Support/Claude/claude_desktop_config.json
    (preserving any existing mcpServers entries):

      "claude-pet": {
        "command": "#{appdir}/ClaudePet.app/Contents/MacOS/ClaudePet",
        "args": ["--mcp"]
      }

    Then fully quit Claude Desktop (Cmd+Q) and reopen it.

    Or run the bundled installer to merge the config automatically:
      curl -fsSL https://raw.githubusercontent.com/loeweErr/ClaudePet/main/install.sh | bash
  EOS

  zap trash: [
    "~/Library/Application Support/ClaudePet",
    "~/Library/Preferences/com.local.ClaudePet.plist",
  ]
end
