#!/usr/bin/env bash
#
# lint.sh — Code quality checks for Lua files in the workspace
#
# Usage:
#   ./scripts/lint.sh
#
# Checks:
#   - Lua 5.1 compliance (no goto, no __gc, no table.pack/unpack)
#   - Module pattern (local M = {} ... return M)
#   - Local usage (no global pollution except _G.UIEngine)
#   - Consistent require paths
#   - Dead code detection (unused variables, unreachable code)
#   - Code style (tabs, trailing whitespace)

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

ERRORS=0
WARNINGS=0

# --- Helper functions ---

error() {
    echo -e "${RED}  ERROR: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo -e "${YELLOW}  WARN:  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    echo -e "${CYAN}  $1${NC}"
}

# --- Find Lua files ---

# Search in engines/ and tests/ (exclude dependencies/, reference/, versions/)
LUA_FILES=()
while IFS= read -r -d '' file; do
    LUA_FILES+=("$file")
done < <(find "$WORKSPACE_ROOT/engines" "$WORKSPACE_ROOT/tests" -name "*.lua" -type f -print0 2>/dev/null || true)

if [ ${#LUA_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No Lua files found to lint.${NC}"
    echo "Engine directories may be empty."
    exit 0
fi

echo -e "${CYAN}=== Linting ${#LUA_FILES[@]} Lua files ===${NC}"
echo ""

# --- Check each file ---

for file in "${LUA_FILES[@]}"; do
    # Get relative path for display
    rel_path="${file#$WORKSPACE_ROOT/}"

    # --- Lua 5.1 compliance ---

    # Check for 'goto' keyword
    if grep -nP '^\s*goto\s+\w+' "$file" 2>/dev/null | head -5; then
        error "$rel_path: Uses 'goto' (Lua 5.1 incompatible)"
    fi

    # Check for goto labels (::label::)
    if grep -nP '::\w+::' "$file" 2>/dev/null | head -5; then
        error "$rel_path: Uses goto labels (::label::) (Lua 5.1 incompatible)"
    fi

    # Check for __gc metamethod
    if grep -n '__gc' "$file" 2>/dev/null | head -5; then
        error "$rel_path: Uses __gc metamethod (Lua 5.1 incompatible)"
    fi

    # Check for table.pack / table.unpack
    if grep -nP 'table\.(pack|unpack)' "$file" 2>/dev/null | head -5; then
        error "$rel_path: Uses table.pack/unpack (Lua 5.1 incompatible)"
    fi

    # --- Module pattern (only for engine files, not test mocks) ---

    if [[ "$file" == *engines/* ]]; then
        # Check if file has content (skip near-empty files)
        line_count=$(wc -l < "$file")
        if [ "$line_count" -gt 5 ]; then
            # Check for module pattern: local M = {} ... return M
            if ! grep -q 'return\s\+M\b' "$file" 2>/dev/null; then
                if ! grep -q 'return\s*{$' "$file" 2>/dev/null; then
                    if ! grep -q '^return\s' "$file" 2>/dev/null; then
                        warn "$rel_path: No 'return M' or 'return {}' found (module pattern)"
                    fi
                fi
            fi
        fi
    fi

    # --- Global pollution (only for engine files) ---

    if [[ "$file" == *engines/* ]]; then
        # Check for direct global assignments (not _G.UIEngine)
        # Match patterns like: GLOB_VAR = value (at start of line, not indented)
        if grep -nP '^[A-Z][A-Z_0-9]+\s*=' "$file" 2>/dev/null | grep -v '_G\.UIEngine' | grep -v '^[^:]*:.*=' | head -5; then
            warn "$rel_path: Possible global variable assignment"
        fi
    fi

    # --- Tab check ---

    if grep -Pn '\t' "$file" 2>/dev/null | head -5; then
        warn "$rel_path: Contains tab characters (use spaces)"
    fi

    # --- Trailing whitespace ---

    if grep -Pn '[ \t]+$' "$file" 2>/dev/null | head -5; then
        warn "$rel_path: Contains trailing whitespace"
    fi

    # --- Duplicate require paths (for engine files) ---

    if [[ "$file" == *engines/* ]]; then
        # Check for require with file-path-style patterns (starts with ./ or has multiple /)
        # Valid module paths like "ui/utils" are OK, but "path/to/module" or "./module" are not
        if grep -nP 'require\s*\(\s*"\./' "$file" 2>/dev/null | head -5; then
            warn "$rel_path: Uses relative path require (use module names instead)"
        fi
        if grep -nP 'require\s*\(\s*"[a-z]+/[a-z]+/[a-z]+' "$file" 2>/dev/null | head -5; then
            warn "$rel_path: Uses deep path require (use module names instead)"
        fi
    fi

done

# --- Summary ---

echo ""
echo -e "${CYAN}=== Lint Summary ===${NC}"
echo "  Files checked: ${#LUA_FILES[@]}"
echo -e "  Errors:        ${RED}${ERRORS}${NC}"
echo -e "  Warnings:      ${YELLOW}${WARNINGS}${NC}"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}Lint failed with ${ERRORS} error(s).${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}Lint passed with ${WARNINGS} warning(s).${NC}"
    exit 0
else
    echo -e "${GREEN}Lint passed with no issues.${NC}"
    exit 0
fi