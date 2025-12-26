#!/usr/bin/env bash
# update.sh - Update NixOS flake inputs and rebuild
#
# Usage: ./update.sh [desktop]
# If no argument provided, auto-detects based on hostname

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect which configuration to use
detect_config() {
    local hostname=$(hostname)
    case "$hostname" in
        desktop)
            echo "desktop"
            ;;
        *)
            echo -e "${YELLOW}Warning: Unknown hostname '$hostname', defaulting to desktop${NC}" >&2
            echo "desktop"
            ;;
    esac
}

CONFIG="${1:-$(detect_config)}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Updating flake inputs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Change to the script directory (where flake.nix lives)
cd "$SCRIPT_DIR"

# Update flake inputs
nix flake update

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🔨 Rebuilding with updated inputs: ${GREEN}${CONFIG}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges for rebuilding. Running with sudo..."
    sudo nixos-rebuild switch --flake ".#${CONFIG}"
else
    nixos-rebuild switch --flake ".#${CONFIG}"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Update complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Changes:"
git diff flake.lock || true
