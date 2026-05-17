#!/usr/bin/env bash
SECUREKEYS_DIR="${SECUREKEYS_DIR:-$HOME/.securekeys}"
VAULT_FILE="$SECUREKEYS_DIR/vault.enc"
SALT_FILE="$SECUREKEYS_DIR/.salt"
META_FILE="$SECUREKEYS_DIR/.meta"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

sk_check_deps() {
  local missing=()
  for cmd in openssl base64; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}[ERROR]${RESET} Missing dependencies: ${missing[*]}" >&2
    echo -e "  Install with: ${CYAN}brew install openssl${RESET} (macOS) or ${CYAN}apt install openssl${RESET} (Linux)" >&2
    return 1
  fi
}

sk_init_vault() {
  sk_check_deps || return 1

  if [[ -d "$SECUREKEYS_DIR" && -f "$VAULT_FILE" ]]; then
    echo -e "${YELLOW}[WARN]${RESET} Vault already exists at ${CYAN}$SECUREKEYS_DIR${RESET}"
    echo -e "  Use ${BOLD}sk destroy${RESET} first if you want to start fresh."
    return 1
  fi

  mkdir -p "$SECUREKEYS_DIR"
  chmod 700 "$SECUREKEYS_DIR"

  # Generate a random salt (hex, 32 bytes = 64 hex chars)
  openssl rand -hex 32 >"$SALT_FILE"
  chmod 600 "$SALT_FILE"

  echo "{\"version\":1,\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >"$META_FILE"
  chmod 600 "$META_FILE"

  # Bootstrap empty JSON vault: {}
  local password
  echo -e "${BOLD}${CYAN}SecureKeys Vault Initialisation${RESET}"
  echo -e "${DIM}Your master password is NEVER stored anywhere. Don't forget it.${RESET}\n"
  password=$(_sk_prompt_password "Set master password: ")
  local confirm
  confirm=$(_sk_prompt_password "Confirm master password: ")

  if [[ "$password" != "$confirm" ]]; then
    rm -rf "$SECUREKEYS_DIR"
    echo -e "\n${RED}[ERROR]${RESET} Passwords do not match. Vault not created."
    return 1
  fi

  echo '{}' | _sk_encrypt "$password" >"$VAULT_FILE" 2>/dev/null
  chmod 600 "$VAULT_FILE"

  echo -e "\n${GREEN}[OK]${RESET} Vault created at ${CYAN}$SECUREKEYS_DIR${RESET}"
  echo -e "${DIM}Add ${BOLD}source \$(sk shell-init)${DIM} to your .zshrc to load keys as env vars.${RESET}"
}

# Derives key from password + stored salt using PBKDF2 (100k iterations, SHA-256)
_sk_encrypt() {
  local password="$1"
  local salt
  salt=$(cat "$SALT_FILE")
  # -a = base64 output, -pbkdf2 = PBKDF2 key derivation, -iter = iterations
  openssl enc -aes-256-cbc -a -pbkdf2 -iter 100000 \
    -pass "pass:${password}${salt}" 2>/dev/null
}

_sk_decrypt() {
  local password="$1"
  local salt
  salt=$(cat "$SALT_FILE")
  openssl enc -d -aes-256-cbc -a -pbkdf2 -iter 100000 \
    -pass "pass:${password}${salt}" 2>/dev/null
}

_sk_prompt_password() {
  local prompt="${1:-Master password: }"
  local password
  printf "${BOLD}%s${RESET}" "$prompt" >&2
  read -rs password
  printf "\n" >&2
  echo "$password"
}

_sk_read_vault() {
  local password="$1"
  if [[ ! -f "$VAULT_FILE" ]]; then
    echo -e "${RED}[ERROR]${RESET} No vault found. Run: ${CYAN}sk init${RESET}" >&2
    return 1
  fi
  local plain
  plain=$(cat "$VAULT_FILE" | _sk_decrypt "$password" 2>/dev/null)
  if [[ -z "$plain" ]]; then
    echo -e "${RED}[ERROR]${RESET} Decryption failed — wrong password or corrupted vault." >&2
    return 1
  fi
  echo "$plain"
}

_sk_write_vault() {
  local password="$1"
  local json="$2"
  local tmp
  tmp=$(mktemp)
  echo "$json" | _sk_encrypt "$password" >"$tmp" 2>/dev/null
  mv "$tmp" "$VAULT_FILE"
  chmod 600 "$VAULT_FILE"
}

_json_get() {
  local json="$1" key="$2"
  echo "$json" |
    grep -oE "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" 2>/dev/null |
    sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"(.*)"/\1/'
}

_json_set() {
  local json="$1" key="$2" value="$3"
  # Escape special chars in value for sed
  local escaped_value
  escaped_value=$(printf '%s' "$value" | sed 's/[&/\]/\\&/g; s/"/\\"/g')
  local escaped_key
  escaped_key=$(printf '%s' "$key" | sed 's/[&/\]/\\&/g')

  if echo "$json" | grep -qE "\"${key}\"[[:space:]]*:"; then
    # Update existing
    echo "$json" | sed -E "s|\"${escaped_key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"${escaped_key}\": \"${escaped_value}\"|g"
  else
    # Insert new key before closing brace
    echo "$json" | sed -E "s|\}$|, \"${escaped_key}\": \"${escaped_value}\"}|"
  fi
}

# Delete a key from flat JSON
_json_delete() {
  local json="$1" key="$2"
  echo "$json" |
    sed -E "s|,?[[:space:]]*\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"||g" |
    sed -E "s|\{[[:space:]]*,|\{|g" |
    sed -E "s|,[[:space:]]*\}|}|g"
}

# List all keys from flat JSON
_json_keys() {
  local json="$1"
  echo "$json" | grep -oE '"[^"]+"[[:space:]]*:' | sed 's/"//g; s/[[:space:]]*://g'
}
