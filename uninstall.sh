#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
LIB_DIR="$HOME/.local/lib/securekeys"

echo -e "\n${BOLD}${CYAN}SecureShell Uninstaller${RESET}\n"

# Remove the sk binary stored in the bin folder? or whatever user passed in env
if [ -f "$INSTALL_DIR/sk" ]; then
  rm "$INSTALL_DIR/sk"
  echo -e "${GREEN}[OK]${RESET} Removed ${CYAN}$INSTALL_DIR/sk${RESET}"
  bin_removed=true
else
  bin_removed=false
  echo -e "${RED}[WARN]${RESET} ${CYAN}$INSTALL_DIR/sk${RESET} not found"
fi

# Remove the library directory
if [ -d "$LIB_DIR" ]; then
  rm -r "$LIB_DIR"
  echo -e "${GREEN}[OK]${RESET} Removed library directory ${CYAN}$LIB_DIR${RESET}"
  lib_removed=true
else
  echo -e "${RED}[WARN]${RESET} Library directory ${CYAN}$LIB_DIR${RESET} not found"
  lib_removed=false
fi

# Remove empty parent directory if it exists
if [ -d "$HOME/.local/lib" ] && [ -z "$(ls -A "$HOME/.local/lib")" ]; then
  rmdir "$HOME/.local/lib"
  echo -e "${GREEN}[OK]${RESET} Removed empty directory ${CYAN}$HOME/.local/lib${RESET}"
fi
if [[ "$bin_removed" == "true" && "$lib_removed" == "true" ]]; then
  echo -e "\n${GREEN}[OK]${RESET} sk uninstalled successfully"
elif [[ "$bin_removed" == "false" || "$lib_removed" == "false" ]]; then
  echo -e "${RED}[WARN]${RESET} Confirm if both the Library and the Binary are removed" 
fi
echo -e "${CYAN}Remember to remove the PATH export from your shell profile (.zshrc / .bashrc)${RESET}\n"
