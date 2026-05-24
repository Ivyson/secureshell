#!/usr/bin/env bash
# General Error code 1
set -Eeuo pipefail #Exit if the return of any func in here returns a non zero value(non zero assumed to be an error of course!)
# Detect the SYSTEM ALREADY
OS=($(uname -a | cut -d " " -f1,2))
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # This should be getting the location of this repo.
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"           # Check if the Install DIr is already set in the environment, default to the linux's bin folder
LIB_DIR="$HOME/.local/lib/securekeys"                    # This will store the keys..

echo -e "\n${BOLD}${CYAN}SecureShell Installer?${RESET}\n"
if [[ ${OS[0]} != "Linux" && ${OS[0]} != "Darwin" ]]; then #Need to confirm for MacOs
  # : # Short for pass, or no operatgion?\
  # break
  echo -e "The Operating Systems supported are {Linux | Darwin}"
  exit 1 # Error
fi

if ! command -v openssl &>/dev/null; then #requires the openssl for encryption of the keys later in the ./lib/crypto.sh
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
  "$REPO_DIR/bin/sk" >"$INSTALL_DIR/sk"
chmod 755 "$INSTALL_DIR/sk"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo -e "${BOLD}Add to your shell profile (.zshrc / .bashrc):${RESET}"
  echo -e "  ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}\n"
fi

echo -e "${GREEN}[OK]${RESET} Installed ${BOLD}sk${RESET} → ${CYAN}$INSTALL_DIR/sk${RESET}"
echo -e "${GREEN}[OK]${RESET} Library   → ${CYAN}$LIB_DIR/crypto.sh${RESET}"
echo -e "\n${DIM}Next step: run ${BOLD}sk init${DIM} to create your vault.${RESET}\n"
