#!/usr/bin/env bash
# ClaudePet one-click installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/loeweErr/ClaudePet/main/install.sh | bash
#   # or, from a local checkout:
#   ./install.sh
#
# This script:
#   1. Verifies macOS >= 13 and a Swift toolchain
#   2. Builds ClaudePet.app (prefers `swift build -c release`, falls back to swiftc)
#   3. Installs the app (default /Applications/ClaudePet.app)
#   4. Registers the claude-pet MCP server in Claude Desktop's config,
#      preserving any existing servers (a timestamped backup is kept)

set -euo pipefail

REPO_URL="https://github.com/loeweErr/ClaudePet.git"
DEFAULT_INSTALL_DIR="/Applications"
APP_NAME="ClaudePet.app"
BIN_NAME="ClaudePet"
CLAUDE_CONFIG="${HOME}/Library/Application Support/Claude/claude_desktop_config.json"

c_red()   { printf '\033[31m%s\033[0m\n' "$*"; }
c_green() { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
c_bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

err()  { c_red "✗ $*" >&2; exit 1; }
info() { printf '· %s\n' "$*"; }
ok()   { c_green "✓ $*"; }

# ---------- environment checks ----------

check_macos() {
    [[ "$(uname -s)" == "Darwin" ]] || err "This installer only supports macOS."
    local ver major
    ver="$(sw_vers -productVersion)"
    major="${ver%%.*}"
    if (( major < 13 )); then
        err "macOS 13 (Ventura) or newer required, detected $ver."
    fi
    ok "macOS $ver"
}

check_swift() {
    if ! command -v swift >/dev/null 2>&1; then
        err "Swift not found. Install with: xcode-select --install"
    fi
    local sv
    sv="$(swift --version 2>&1 | head -1)"
    ok "Swift detected — $sv"
}

# Detect whether we have a full Xcode (with Platforms/) or just CommandLineTools.
# `swift build` needs Platforms/MacOSX.platform; CLT alone forces the swiftc path.
detect_build_mode() {
    local dev_dir platforms
    dev_dir="$(xcode-select -p 2>/dev/null || true)"
    platforms="${dev_dir}/Platforms/MacOSX.platform"
    if [[ -n "$dev_dir" && -d "$platforms" ]]; then
        echo "swiftpm"
    else
        echo "swiftc"
    fi
}

# ---------- source acquisition ----------

# If run via curl|bash there is no local checkout; clone into a temp dir.
# If run from inside the repo (Sources/ClaudePet present), use it in place.
acquire_source() {
    if [[ -d "Sources/ClaudePet" && -f "Package.swift" ]]; then
        SRC_DIR="$(pwd)"
        info "Using local checkout at $SRC_DIR"
        CLEANUP_SRC=0
    else
        SRC_DIR="$(mktemp -d -t claudepet-src.XXXXXX)"
        CLEANUP_SRC=1
        info "Cloning $REPO_URL → $SRC_DIR"
        git clone --depth 1 "$REPO_URL" "$SRC_DIR" >/dev/null 2>&1 \
            || err "git clone failed."
    fi
}

# ---------- build ----------

build_app() {
    local mode="$1" build_dir
    build_dir="$(mktemp -d -t claudepet-build.XXXXXX)"
    APP_BUILD="${build_dir}/${APP_NAME}"
    mkdir -p "${APP_BUILD}/Contents/MacOS" "${APP_BUILD}/Contents/Resources"

    pushd "$SRC_DIR" >/dev/null

    if [[ "$mode" == "swiftpm" ]]; then
        info "Building with swift build -c release"
        swift build -c release >/dev/null
        cp ".build/release/${BIN_NAME}" "${APP_BUILD}/Contents/MacOS/${BIN_NAME}"
    else
        info "Building with swiftc (CommandLineTools mode)"
        local arch target
        arch="$(uname -m)"
        case "$arch" in
            arm64)  target="arm64-apple-macos13" ;;
            x86_64) target="x86_64-apple-macos13" ;;
            *)      err "Unsupported arch: $arch" ;;
        esac
        swiftc -O -target "$target" \
            -framework AppKit -framework Foundation \
            -o "${APP_BUILD}/Contents/MacOS/${BIN_NAME}" \
            Sources/ClaudePet/*.swift
    fi

    cp Resources/meow.m4a "${APP_BUILD}/Contents/Resources/meow.m4a"

    cat > "${APP_BUILD}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>ClaudePet</string>
  <key>CFBundleIdentifier</key><string>com.local.ClaudePet</string>
  <key>CFBundleName</key><string>ClaudePet</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST

    popd >/dev/null
    ok "Built ${APP_BUILD}"
}

# ---------- install ----------

install_app() {
    local target_dir target_app
    if [[ -t 0 ]]; then
        printf 'Install location [%s]: ' "$DEFAULT_INSTALL_DIR"
        read -r target_dir
    else
        target_dir=""
    fi
    target_dir="${target_dir:-$DEFAULT_INSTALL_DIR}"
    target_app="${target_dir}/${APP_NAME}"

    if [[ -d "$target_app" ]]; then
        c_yellow "An existing ${target_app} will be replaced."
        if [[ -t 0 ]]; then
            printf 'Continue? [y/N]: '
            local ans; read -r ans
            [[ "$ans" =~ ^[Yy]$ ]] || err "Aborted."
        fi
        rm -rf "$target_app"
    fi

    mkdir -p "$target_dir"
    mv "$APP_BUILD" "$target_app"
    INSTALLED_APP="$target_app"
    ok "Installed → $target_app"
}

# ---------- claude_desktop_config.json merge ----------

# Safety contract: if the file exists, every top-level key the user had stays;
# only mcpServers.claude-pet is added or refreshed. A timestamped .bak is left
# beside the original. Atomic replace via a temp file + mv.
merge_claude_config() {
    local exec_path="${INSTALLED_APP}/Contents/MacOS/${BIN_NAME}"
    mkdir -p "$(dirname "$CLAUDE_CONFIG")"

    local backup tmp ts
    ts="$(date +%Y%m%d-%H%M%S)"
    backup="${CLAUDE_CONFIG}.bak.${ts}"
    tmp="$(mktemp "${CLAUDE_CONFIG}.XXXXXX")"

    if [[ -f "$CLAUDE_CONFIG" ]]; then
        cp "$CLAUDE_CONFIG" "$backup"
        info "Backup → $backup"
    fi

    EXEC_PATH="$exec_path" CFG="$CLAUDE_CONFIG" TMP="$tmp" python3 - <<'PY' || err "Failed to update Claude Desktop config."
import json, os, sys
cfg_path = os.environ["CFG"]
tmp_path = os.environ["TMP"]
exec_path = os.environ["EXEC_PATH"]

if os.path.exists(cfg_path):
    with open(cfg_path, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            sys.exit(f"existing config is not valid JSON: {e}")
    if not isinstance(data, dict):
        sys.exit("existing config is not a JSON object")
else:
    data = {}

servers = data.get("mcpServers")
if not isinstance(servers, dict):
    servers = {}

servers["claude-pet"] = {
    "command": exec_path,
    "args": ["--mcp"],
}
data["mcpServers"] = servers

with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

    mv "$tmp" "$CLAUDE_CONFIG"
    ok "Updated $CLAUDE_CONFIG"
}

# ---------- cleanup ----------

cleanup() {
    if [[ "${CLEANUP_SRC:-0}" == "1" && -n "${SRC_DIR:-}" && -d "$SRC_DIR" ]]; then
        rm -rf "$SRC_DIR"
    fi
}
trap cleanup EXIT

# ---------- main ----------

main() {
    c_bold "ClaudePet installer"
    check_macos
    check_swift
    local mode; mode="$(detect_build_mode)"
    info "Build mode: $mode"

    acquire_source
    build_app "$mode"
    install_app
    merge_claude_config

    echo
    c_bold "All set."
    cat <<EOF

Next steps:
  1. Quit Claude Desktop completely (Cmd+Q) and reopen it.
  2. In any conversation, try: "喂猫" / "feed the cat" — Claude will call pet_feed.
  3. The cat appears on your desktop and reacts. Click the menu bar ✦ for status.

If something looks off, the previous Claude config (if any) is at:
  ${CLAUDE_CONFIG}.bak.<timestamp>
EOF
}

main "$@"
