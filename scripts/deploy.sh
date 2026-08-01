#!/usr/bin/env bash
#
# deploy.sh — Deploy engines + dependencies + patched mods to game folder
#
# Usage:
#   ./scripts/deploy.sh              # Deploy to deployment/game/
#   ./scripts/deploy.sh --vortex     # Deploy to game + Vortex staging
#
# Deployment targets (user creates symlinks):
#   deployment/game/  -> /path/to/cyber_engine_tweaks/mods/
#   deployment/vortex/ -> <vortex-staging-path>/

set -euo pipefail

# Resolve workspace root (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Parse arguments ---

DEPLOY_VORTEX=false

for arg in "$@"; do
    case "$arg" in
        --vortex)
            DEPLOY_VORTEX=true
            ;;
        --help|-h)
            echo "Usage: $0 [--vortex]"
            echo ""
            echo "Options:"
            echo "  --vortex    Also deploy to deployment/vortex/"
            echo ""
            echo "Deployment targets:"
            echo "  deployment/game/   -> game CET mods folder (symlink)"
            echo "  deployment/vortex/ -> Vortex staging (symlink)"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown argument '${arg}'${NC}"
            echo "Usage: $0 [--vortex]"
            exit 1
            ;;
    esac
done

# --- Source paths ---

ENGINES_DIR="$WORKSPACE_ROOT/engines"
DEPS_DIR="$WORKSPACE_ROOT/dependencies"
PATCHED_DIR="$WORKSPACE_ROOT/patched"
GAME_DIR="$WORKSPACE_ROOT/deployment/game"
VORTEX_DIR="$WORKSPACE_ROOT/deployment/vortex"

UI_ENGINE_SRC="$ENGINES_DIR/UI-Engine"
CONFIG_ENGINE_SRC="$ENGINES_DIR/Config-Engine"
ENGINE_0_SRC="$DEPS_DIR/0-Engine"

# --- Validate deployment target ---

if [ ! -d "$GAME_DIR" ]; then
    echo -e "${RED}Error: deployment/game/ directory not found.${NC}"
    echo ""
    echo "Create a symlink to your game CET mods folder:"
    echo "  ln -s /path/to/cyber_engine_tweaks/mods deployment/game"
    exit 1
fi

# Check if game dir is a symlink and if target exists
if [ -L "$GAME_DIR" ] && [ ! -e "$GAME_DIR" ]; then
    echo -e "${RED}Error: deployment/game/ symlink is broken (target does not exist).${NC}"
    echo "Current symlink target: $(readlink "$GAME_DIR")"
    echo "Please fix the symlink to point to your game CET mods folder."
    exit 1
fi

# --- Deploy function ---

deploy_to_target() {
    local target_dir="$1"
    local target_name="$2"

    echo -e "${GREEN}=== Deploying to ${target_name} ===${NC}"

    # Deploy UI-Engine
    if [ -d "$UI_ENGINE_SRC" ] && [ "$(ls -A "$UI_ENGINE_SRC" 2>/dev/null)" ]; then
        mkdir -p "$target_dir/0-Engine-UI"
        cp -r "$UI_ENGINE_SRC"/* "$target_dir/0-Engine-UI/"
        echo -e "${GREEN}  ✓ UI-Engine -> ${target_name}/0-Engine-UI/${NC}"
    else
        echo -e "${YELLOW}  ⊘ UI-Engine skipped (empty)${NC}"
    fi

    # Deploy Config-Engine
    if [ -d "$CONFIG_ENGINE_SRC" ] && [ "$(ls -A "$CONFIG_ENGINE_SRC" 2>/dev/null)" ]; then
        mkdir -p "$target_dir/0-Engine-Config"
        cp -r "$CONFIG_ENGINE_SRC"/* "$target_dir/0-Engine-Config/"
        echo -e "${GREEN}  ✓ Config-Engine -> ${target_name}/0-Engine-Config/${NC}"
    else
        echo -e "${YELLOW}  ⊘ Config-Engine skipped (empty)${NC}"
    fi

    # Deploy 0-Engine dependency
    if [ -d "$ENGINE_0_SRC" ] && [ "$(ls -A "$ENGINE_0_SRC" 2>/dev/null)" ]; then
        mkdir -p "$target_dir/0-Engine"
        cp -r "$ENGINE_0_SRC"/* "$target_dir/0-Engine/"
        echo -e "${GREEN}  ✓ 0-Engine -> ${target_name}/0-Engine/${NC}"
    else
        echo -e "${YELLOW}  ⊘ 0-Engine skipped (not found or empty)${NC}"
    fi

    # Deploy patched mods
    if [ -d "$PATCHED_DIR" ] && [ "$(ls -A "$PATCHED_DIR" 2>/dev/null)" ]; then
        # Copy patched content, preserving directory structure
        find "$PATCHED_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r patched_subdir; do
            dir_name="$(basename "$patched_subdir")"
            if [ "$(ls -A "$patched_subdir" 2>/dev/null)" ]; then
                mkdir -p "$target_dir/$dir_name"
                cp -r "$patched_subdir"/* "$target_dir/$dir_name/"
                echo -e "${GREEN}  ✓ Patched/${dir_name} -> ${target_name}/${dir_name}/${NC}"
            fi
        done
    else
        echo -e "${YELLOW}  ⊘ Patched mods skipped (none found)${NC}"
    fi

    echo ""
}

# --- Deploy to game ---

deploy_to_target "$GAME_DIR" "game"

# --- Deploy to Vortex (optional) ---

if [ "$DEPLOY_VORTEX" = true ]; then
    if [ ! -d "$VORTEX_DIR" ]; then
        echo -e "${RED}Error: deployment/vortex/ directory not found.${NC}"
        echo "Create a symlink to your Vortex staging folder:"
        echo "  ln -s /path/to/vortex/staging deployment/vortex"
        exit 1
    fi

    if [ -L "$VORTEX_DIR" ] && [ ! -e "$VORTEX_DIR" ]; then
        echo -e "${RED}Error: deployment/vortex/ symlink is broken (target does not exist).${NC}"
        echo "Current symlink target: $(readlink "$VORTEX_DIR")"
        exit 1
    fi

    deploy_to_target "$VORTEX_DIR" "vortex"
fi

echo -e "${GREEN}Deployment complete.${NC}"