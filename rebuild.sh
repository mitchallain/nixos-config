#!/usr/bin/env bash
# rebuild.sh - Rebuild NixOS configuration
#
# Usage: ./rebuild.sh [desktop]
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
echo -e "🔨 Rebuilding NixOS configuration: ${GREEN}${CONFIG}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if we're running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script requires root privileges. Running with sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Change to the script directory (where flake.nix lives)
cd "$SCRIPT_DIR"

# Build and switch to the new configuration
nixos-rebuild switch --flake ".#${CONFIG}"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Rebuild complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
