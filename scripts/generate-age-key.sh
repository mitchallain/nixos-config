#!/usr/bin/env bash
# generate-age-key.sh - Generate an age key for sops-nix
#
# This script generates an age key from the host's SSH key.
# Run this on each NixOS system that needs to decrypt secrets.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Generating age key for sops-nix"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Don't run this as root!${NC}"
    exit 1
fi

# SSH key paths
SSH_HOST_KEY="/etc/ssh/ssh_host_ed25519_key"
SSH_HOST_KEY_PUB="/etc/ssh/ssh_host_ed25519_key.pub"

# Check if SSH host key exists
if [[ ! -f "$SSH_HOST_KEY" ]]; then
    echo -e "${RED}Error: SSH host key not found at $SSH_HOST_KEY${NC}"
    echo "This script should be run on a NixOS system with SSH configured."
    exit 1
fi

# Generate age public key, installing ssh-to-age temporarily if needed
echo "Generating age public key from SSH host key..."
if ! command -v ssh-to-age &> /dev/null; then
    echo -e "${YELLOW}ssh-to-age not found. Installing temporarily...${NC}"
    AGE_PUBLIC_KEY=$(nix-shell -p ssh-to-age --run "cat $SSH_HOST_KEY_PUB | ssh-to-age")
else
    AGE_PUBLIC_KEY=$(cat "$SSH_HOST_KEY_PUB" | ssh-to-age)
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Age public key generated!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Your age public key is:"
echo -e "${GREEN}$AGE_PUBLIC_KEY${NC}"
echo
echo "Next steps:"
echo "1. Add this key to .sops.yaml in your sops-secrets repo"
echo "2. Create a secrets file: sops secrets/fractal.yaml"
echo "3. Add your secrets to the file"
echo
echo "The age private key is derived at runtime from the SSH host key at:"
echo "$SSH_HOST_KEY"
echo
