#!/usr/bin/env bash
#
# version.sh — Snapshot all engines to versions/vX.Y.Z/
#
# Usage:
#   ./scripts/version.sh v0.1.0
#   ./scripts/version.sh v0.1.0-core
#   ./scripts/version.sh v0.2.0-theme
#
# Creates a copy of all engines in versions/vX.Y.Z/ with a manifest file
# containing version, timestamp, git hash, file count, and line count.

set -euo pipefail

# Resolve workspace root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Validate arguments ---

if [ $# -ne 1 ]; then
    echo -e "${RED}Error: Expected 1 argument (version string)${NC}"
    echo "Usage: $0 vX.Y.Z[-suffix]"
    echo "Examples:"
    echo "  $0 v0.1.0"
    echo "  $0 v0.1.0-core"
    exit 1
fi

VERSION="$1"

# Validate semver format: vX.Y.Z or vX.Y.Z-suffix
if ! echo "$VERSION" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$'; then
    echo -e "${RED}Error: Invalid version format '${VERSION}'${NC}"
    echo "Expected format: vX.Y.Z or vX.Y.Z-suffix"
    echo "Examples: v0.1.0, v0.1.0-core, v0.2.0-theme"
    exit 1
fi

# --- Check workspace structure ---

ENGINES_DIR="$WORKSPACE_ROOT/engines"
VERSIONS_DIR="$WORKSPACE_ROOT/versions"

if [ ! -d "$ENGINES_DIR" ]; then
    echo -e "${RED}Error: engines/ directory not found at ${ENGINES_DIR}${NC}"
    exit 1
fi

if [ ! -d "$VERSIONS_DIR" ]; then
    mkdir -p "$VERSIONS_DIR"
    echo -e "${YELLOW}Created versions/ directory${NC}"
fi

# --- Check that at least one engine has content ---

UI_ENGINE_DIR="$ENGINES_DIR/UI-Engine"
CONFIG_ENGINE_DIR="$ENGINES_DIR/Config-Engine"

has_content=false

if [ -d "$UI_ENGINE_DIR" ] && [ "$(ls -A "$UI_ENGINE_DIR" 2>/dev/null)" ]; then
    has_content=true
fi

if [ -d "$CONFIG_ENGINE_DIR" ] && [ "$(ls -A "$CONFIG_ENGINE_DIR" 2>/dev/null)" ]; then
    has_content=true
fi

if [ "$has_content" = false ]; then
    echo -e "${RED}Error: No engine directories have content to snapshot.${NC}"
    echo "engines/UI-Engine/ and engines/Config-Engine/ are both empty."
    exit 1
fi

# --- Create snapshot ---

SNAPSHOT_DIR="$VERSIONS_DIR/$VERSION"

if [ -d "$SNAPSHOT_DIR" ]; then
    echo -e "${YELLOW}Warning: Version ${VERSION} already exists at ${SNAPSHOT_DIR}${NC}"
    echo "Overwriting existing snapshot..."
    rm -rf "$SNAPSHOT_DIR"
fi

mkdir -p "$SNAPSHOT_DIR"

# --- Copy engines ---

ui_files=0
ui_lines=0
config_files=0
config_lines=0

# Copy UI-Engine
if [ -d "$UI_ENGINE_DIR" ] && [ "$(ls -A "$UI_ENGINE_DIR" 2>/dev/null)" ]; then
    cp -r "$UI_ENGINE_DIR" "$SNAPSHOT_DIR/UI-Engine"
    ui_files=$(find "$SNAPSHOT_DIR/UI-Engine" -type f | wc -l)
    ui_lines=$(find "$SNAPSHOT_DIR/UI-Engine" -type f -name "*.lua" -exec cat {} + 2>/dev/null | wc -l)
    echo -e "${GREEN}  Copied UI-Engine: ${ui_files} files, ${ui_lines} lines${NC}"
fi

# Copy Config-Engine
if [ -d "$CONFIG_ENGINE_DIR" ] && [ "$(ls -A "$CONFIG_ENGINE_DIR" 2>/dev/null)" ]; then
    cp -r "$CONFIG_ENGINE_DIR" "$SNAPSHOT_DIR/Config-Engine"
    config_files=$(find "$SNAPSHOT_DIR/Config-Engine" -type f | wc -l)
    config_lines=$(find "$SNAPSHOT_DIR/Config-Engine" -type f -name "*.lua" -exec cat {} + 2>/dev/null | wc -l)
    echo -e "${GREEN}  Copied Config-Engine: ${config_files} files, ${config_lines} lines${NC}"
fi

# --- Generate manifest ---

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Get git hash if in a git repo
GIT_HASH="n/a"
if git -C "$WORKSPACE_ROOT" rev-parse --short HEAD >/dev/null 2>&1; then
    GIT_HASH="$(git -C "$WORKSPACE_ROOT" rev-parse --short HEAD)"
fi

MANIFEST_FILE="$SNAPSHOT_DIR/manifest.txt"
cat > "$MANIFEST_FILE" <<EOF
Version: ${VERSION}
Timestamp: ${TIMESTAMP}
Git Hash: ${GIT_HASH}
UI-Engine Files: ${ui_files}
UI-Engine Lines: ${ui_lines}
Config-Engine Files: ${config_files}
Config-Engine Lines: ${config_lines}
EOF

# --- Summary ---

echo ""
echo -e "${GREEN}=== Snapshot Created ===${NC}"
echo "  Version:    ${VERSION}"
echo "  Location:   ${SNAPSHOT_DIR}"
echo "  Timestamp:  ${TIMESTAMP}"
echo "  Git Hash:   ${GIT_HASH}"
echo "  Manifest:   ${MANIFEST_FILE}"
echo ""
echo "  UI-Engine:     ${ui_files} files, ${ui_lines} lines"
echo "  Config-Engine: ${config_files} files, ${config_lines} lines"