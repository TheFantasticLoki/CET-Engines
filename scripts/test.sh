#!/usr/bin/env bash
#
# test.sh — Run the test suite
#
# Usage:
#   ./scripts/test.sh
#
# Executes tests/init.lua with the Lua 5.1 interpreter.
# Reports pass/fail counts and errors.

set -euo pipefail

# Resolve workspace root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

TEST_RUNNER="$WORKSPACE_ROOT/tests/init.lua"

# --- Check that test runner exists ---

if [ ! -f "$TEST_RUNNER" ]; then
    echo -e "${RED}Error: Test runner not found at ${TEST_RUNNER}${NC}"
    exit 1
fi

# --- Find Lua interpreter ---

LUA_CMD=""

# Try lua5.1 first, then lua, then luajit
for cmd in lua5.1 lua luajit; do
    if command -v "$cmd" >/dev/null 2>&1; then
        # Verify it's Lua 5.1
        version=$("$cmd" -v 2>&1 | head -1)
        if echo "$version" | grep -qi '5\.1\|luajit'; then
            LUA_CMD="$cmd"
            break
        fi
    fi
done

# If no 5.1 found, try any lua
if [ -z "$LUA_CMD" ]; then
    for cmd in lua lua5.1 luajit; do
        if command -v "$cmd" >/dev/null 2>&1; then
            LUA_CMD="$cmd"
            echo -e "${YELLOW}Warning: Using $cmd (Lua 5.1 recommended for CET compatibility)${NC}"
            break
        fi
    done
fi

if [ -z "$LUA_CMD" ]; then
    echo -e "${RED}Error: No Lua interpreter found.${NC}"
    echo "Install Lua 5.1:"
    echo "  Ubuntu/Debian: sudo apt install lua5.1"
    echo "  macOS:         brew install lua@5.1"
    echo "  Arch:          sudo pacman -S lua51"
    exit 1
fi

echo -e "${CYAN}=== Running Tests ===${NC}"
echo "  Interpreter: $LUA_CMD"
echo "  Runner:      ${TEST_RUNNER#$WORKSPACE_ROOT/}"
echo ""

# --- Run tests ---

# Set package.path to include workspace root and engine directories for requires
# Engine modules use short paths like "ui/utils" relative to engines/0-Mod-Engine/
export LUA_PATH="$WORKSPACE_ROOT/?.lua;$WORKSPACE_ROOT/?/init.lua;$WORKSPACE_ROOT/engines/0-Mod-Engine/?.lua;$WORKSPACE_ROOT/engines/0-Mod-Engine/?/init.lua;;"

# Run with timeout to prevent hanging
if timeout 30 "$LUA_CMD" "$TEST_RUNNER" 2>&1; then
    echo ""
    echo -e "${GREEN}=== Tests Complete ===${NC}"
else
    EXIT_CODE=$?
    echo ""
    if [ "$EXIT_CODE" -eq 124 ]; then
        echo -e "${RED}Error: Tests timed out after 30 seconds${NC}"
    else
        echo -e "${RED}=== Tests Failed (exit code: $EXIT_CODE) ===${NC}"
    fi
    exit "$EXIT_CODE"
fi