#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/src}"
LIB_DIR="$HOME/.local/lib/securekeys"

echo -e "\n${BOLD}${CYAN}SecureKeys Installer${RESET}\n"

if ! command -v openssl &>/dev/null; then
  echo -e "${RED}[ERROR]${RESET} openssl is required."
  echo -e "  macOS: ${CYAN}brew install openssl${RESET}"
  echo -e "  Linux: ${CYAN}sudo apt install openssl${RESET}"
  exit 1
fi

mkdir -p "$LIB_DIR"
cp "$REPO_DIR/lib/crypto.sh" "$LIB_DIR/crypto.sh"
chmod 644 "$LIB_DIR/crypto.sh"

mkdir -p "$INSTALL_DIR"
sed "s|source \"\$SCRIPT_DIR/../lib/crypto.sh\"|source \"$LIB_DIR/crypto.sh\"|g" \
  "$REPO_DIR/src/sk" >"$INSTALL_DIR/sk"
chmod 755 "$INSTALL_DIR/sk"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo -e "${BOLD}Add to your shell profile (.zshrc / .bashrc):${RESET}"
  echo -e "  ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}\n"
fi

echo -e "${GREEN}[OK]${RESET} Installed ${BOLD}sk${RESET} → ${CYAN}$INSTALL_DIR/sk${RESET}"
echo -e "${GREEN}[OK]${RESET} Library   → ${CYAN}$LIB_DIR/crypto.sh${RESET}"
echo -e "\n${DIM}Next step: run ${BOLD}sk init${DIM} to create your vault.${RESET}\n"
