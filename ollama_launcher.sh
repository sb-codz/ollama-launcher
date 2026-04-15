#!/usr/bin/env bash
# ==============================================================================
# Project   : Ollama Launcher
# Author    : Shibu (sb-codz)
# GitHub    : https://github.com/sb-codz/ollama-launcher
# License   : MIT (with additional disclaimer — see LICENSE and DISCLAIMER.md)
#
# ⚠️  UNOFFICIAL PROJECT — NOT AFFILIATED WITH OLLAMA OR THIRD-PARTY PROVIDERS
#     USE AT YOUR OWN RISK. SEE DISCLAIMER.md FOR FULL LEGAL TERMS.
# ==============================================================================
set -euo pipefail

# ==============================
# BASH VERSION CHECK
# ==============================
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]] || \
   [[ "${BASH_VERSINFO[0]:-0}" -eq 4 && "${BASH_VERSINFO[1]:-0}" -lt 3 ]]; then
  echo "ERROR: This script requires Bash 4.3 or higher. Found: ${BASH_VERSION:-unknown}" >&2
  exit 1
fi

# ==============================
# CONFIG
# ==============================
CONFIG_FILE="$HOME/.ollama_launcher.conf"
DEBUG=${DEBUG:-false}
[ "$DEBUG" = true ] && set -x

# ==============================
# COLORS
# ==============================
RESET='\033[0m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
BOLD='\033[1m'

# ==============================
# LOGGING
# ==============================
info()  { printf "\n${BLUE}INFO:${RESET} %s\n" "$1"; }
warn()  { printf "\n${YELLOW}WARN:${RESET} %s\n" "$1"; }
error() { printf "\n${RED}ERROR:${RESET} %s\n" "$1"; }

# ==============================
# ASK
# ==============================
ask() {  local prompt="$1" response
  while true; do
    printf "\n${CYAN}%s${RESET}\n" "$prompt"
    read -rp "[y/N]: " response
    case "$response" in
      [Yy]*) return 0 ;;
      ""|[Nn]*) return 1 ;;
      *) warn "Please answer yes or no." ;;
    esac
  done
}

# ==============================
# CATEGORY HEADER HELPER
# ==============================
get_category_header() {
  local cat="$1"
  local title="${cat^^}"
  local padding="━━ "
  printf "\n${CYAN}${BOLD}%s%s%s${RESET}\n" "$padding" "$title" "$padding"
}

# ==============================
# MENU (with category headers)
# ==============================
MENU_RESULT_FILE=""

menu_select() {
  local title="$1"
  local -n _menu_arr=$2
  local -n _cat_index=$3
  local selected=0
  local key
  local total=${#_menu_arr[@]}

  while true; do
    printf "\033c" >&2
    printf "${CYAN}${BOLD}%s${RESET}\n" "$title" >&2
    printf "  ${YELLOW}↑↓${RESET} navigate  ${GREEN}Enter${RESET} select  ${RED}Ctrl+C${RESET} exit\n\n" >&2

    local last_cat="__none__"
    for i in "${!_menu_arr[@]}"; do
      local item="${_menu_arr[$i]}"
      local cat="${_cat_index[$i]}"

      if [[ "$cat" != "$last_cat" ]]; then
        get_category_header "$cat" >&2
        last_cat="$cat"
      fi
      if [ "$i" -eq "$selected" ]; then
        printf "${GREEN}  ▶ %s${RESET}\n" "$item" >&2
      else
        printf "    %s\n" "$item" >&2
      fi
    done
    printf "\n" >&2

    IFS= read -rsn1 key || true

    if [[ "$key" == $'\x1b' ]]; then
      IFS= read -rsn2 key || true
      case "$key" in
        "[A") (( selected-- )) || true ;;
        "[B") (( selected++ )) || true ;;
      esac
    elif [[ -z "$key" ]]; then
      echo "$selected" > "$MENU_RESULT_FILE"
      return 0
    fi

    (( selected < 0 )) && selected=$(( total - 1 )) || true
    (( selected >= total )) && selected=0 || true
  done
}

# ==============================
# UTILS
# ==============================
command_exists() { command -v "$1" >/dev/null 2>&1; }

pkg_install() {
  if command_exists apt-get; then
    sudo apt-get install -y "$@" 2>/dev/null || apt-get install -y "$@" 2>/dev/null || true
  elif command_exists yum; then
    sudo yum install -y "$@" 2>/dev/null || yum install -y "$@" 2>/dev/null || true
  elif command_exists brew; then
    brew install "$@" 2>/dev/null || true
  elif command_exists pkg; then
    pkg install -y "$@" 2>/dev/null || true
  else
    warn "No supported package manager found. Install dependencies manually."
    return 1
  fi
}

# ==============================
# BASE DEPS
# ==============================
install_base_deps() {  pkg_install curl git || true
}

# ==============================
# NODEJS
# ==============================
install_nodejs() {
  if command_exists node; then
    return 0
  fi
  info "Installing Node.js..."
  pkg_install nodejs || {
    warn "Node.js installation failed. Some apps may not work."
    return 1
  }
}

# ==============================
# OLLAMA
# ==============================
OLLAMA_STARTED_BY_US=false

install_ollama() {
  if ! command_exists ollama; then
    info "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh || {
      error "Ollama installation failed"
      return 1
    }
  fi
}

start_ollama() {
  if ! pgrep -x ollama >/dev/null 2>&1; then
    info "Starting Ollama server..."
    ollama serve >/dev/null 2>&1 &
    sleep 3
    OLLAMA_STARTED_BY_US=true
  fi
}

stop_ollama() {
  if [ "$OLLAMA_STARTED_BY_US" = true ]; then
    pkill ollama 2>/dev/null || true
  fi
  [ -n "$MENU_RESULT_FILE" ] && [ -f "$MENU_RESULT_FILE" ] && rm -f "$MENU_RESULT_FILE"
}
trap stop_ollama EXIT INT TERM

# ==============================# MODELS - CATEGORIZED
# ==============================
declare -A MODEL_CATEGORIES
MODEL_CATEGORIES=(
  [cogito]="cogito-2.1:671b-cloud"
  [deepseek]="deepseek-v3.1:671b-cloud deepseek-v3.2:cloud"
  [devstral]="devstral-2:123b-cloud devstral-small-2:24b-cloud"
  [gemini]="gemini-3-flash-preview:cloud"
  [gemma]="gemma3:cloud gemma4:cloud gemma4:4b-cloud gemma4:26b-cloud gemma4:31b-cloud"
  [glm]="glm-4.6:cloud glm-4.7:cloud glm-4.7-flash glm-5:cloud glm-5.1:cloud"
  [gpt-oss]="gpt-oss:20b-cloud gpt-oss:120b-cloud"
  [kimi]="kimi-k2:cloud kimi-k2-thinking:cloud kimi-k2.5:cloud"
  [minimax]="minimax-m2:cloud minimax-m2.1:cloud minimax-m2.5:cloud minimax-m2.7:cloud"
  [ministral]="ministral-3:3b-cloud ministral-3:8b-cloud ministral-3:14b-cloud"
  [mistral]="mistral-large-3:cloud"
  [nemotron]="nemotron-3-nano:4b-cloud nemotron-3-nano:30b-cloud nemotron-3-super:120b-cloud"
  [qwen]="qwen3.5:cloud qwen3.5:2b-cloud qwen3.5:4b-cloud qwen3.5:9b-cloud qwen3.5:27b-cloud qwen3.5:35b-cloud qwen3.5:122b-cloud qwen3.5:397b-cloud qwen3-coder:30b-cloud qwen3-coder:480b-cloud qwen3-coder-next:cloud qwen3-next:80b-cloud qwen3-vl:2b-cloud qwen3-vl:4b-cloud qwen3-vl:8b-cloud qwen3-vl:30b-cloud qwen3-vl:32b-cloud qwen3-vl:235b-cloud"
  [rnj]="rnj-1:8b-cloud"
)

MODELS=()
MODEL_CATEGORIES_INDEX=()
for category in "${!MODEL_CATEGORIES[@]}"; do
  for model in ${MODEL_CATEGORIES[$category]}; do
    MODELS+=("$model")
    MODEL_CATEGORIES_INDEX+=("$category")
  done
done

is_cloud_model() { [[ "${1:-}" == *":cloud" ]]; }

ensure_model() {
  local model="${1:-}"
  if [ -z "$model" ]; then
    error "No model specified."
    return 1
  fi
  if is_cloud_model "$model"; then
    info "Cloud model selected — routing handled by Ollama API: $model"
    return 0
  fi
  if ! ollama list 2>/dev/null | awk '{print $1}' | grep -qxF "$model"; then
    info "Downloading model: $model"
    ollama pull "$model" || { error "Failed to pull model: $model"; return 1; }
  fi
}

# ==============================
# CLOUD AUTH VERIFICATION
# ==============================
verify_ollama_cloud_auth() {
  if ! command_exists ollama; then
    error "Ollama CLI not found. Cloud models require Ollama to be installed."
    return 1
  fi

  local has_auth=false
  [ -d "$HOME/.ollama" ] && [ -f "$HOME/.ollama/apikey" ] && has_auth=true
  [ -n "${OLLAMA_API_KEY:-}" ] && has_auth=true

  if [ "$has_auth" = false ]; then
    printf "\n${YELLOW}${BOLD}⚠️  Cloud Authentication Required${RESET}\n" >&2
    printf "${YELLOW}Cloud models (:cloud) require a verified Ollama account.${RESET}\n" >&2
    printf "${YELLOW}You must complete 'ollama signin' before first use.${RESET}\n\n" >&2

    if ask "Launch Ollama sign-in process now?"; then
      info "Starting Ollama sign-in... (follow terminal/browser prompts)"
      ollama signin && info "Authentication successful." || {
        error "Sign-in failed or cancelled. Cloud models cannot be used."
        return 1
      }
    else
      warn "Authentication declined. Run 'ollama signin' manually and retry."
      return 1
    fi
  else
    info "Ollama cloud authentication detected."
  fi
  return 0
}

# ==============================
# APPS
# ==============================
APPS=("ollama" "codex" "opencode" "claude" "droid" "vscode")
APP_CATEGORIES_INDEX=()
for _ in "${APPS[@]}"; do APP_CATEGORIES_INDEX+=("application"); done

install_app() {
  case "${1:-}" in
    codex)
      install_nodejs
      info "Installing OpenAI Codex CLI..."
      npm install -g @openai/codex 2>/dev/null || { error "Failed to install codex."; return 1; }
      ;;
    opencode)
      info "Installing OpenCode CLI..."
      curl -fsSL https://opencode.ai/install | bash || { error "OpenCode installation failed."; return 1; }
      ;;
    claude)      info "Installing Claude Code..."
      curl -fsSL https://claude.ai/install.sh | bash || { error "Claude Code installation failed."; return 1; }
      ;;
    droid)
      info "Installing Factory Droid CLI..."
      curl -fsSL https://app.factory.ai/cli | sh || { error "Droid installation failed."; return 1; }
      ;;
    vscode)
      warn "VS Code requires manual installation:"
      warn "  1. Install VS Code: https://code.visualstudio.com/download"
      warn "  2. Install 'GitHub Copilot Chat' extension"
      ask "Proceed with Ollama configuration for VS Code?" || return 1
      ;;
    ollama) return 0 ;;
    *) error "Unsupported application: ${1:-}"; return 1 ;;
  esac
}

ensure_app() {
  local app="${1:-}"
  [[ "$app" == "ollama" || "$app" == "vscode" ]] && return 0
  if ! command_exists "$app"; then
    warn "$app not found in PATH"
    if ask "Install $app now?"; then
      install_app "$app" || { error "Installation failed for $app"; return 1; }
    else
      warn "Skipping $app"
      return 1
    fi
  fi
  return 0
}

launch_app() {
  local app="${1:-}" model="${2:-}"
  case "$app" in
    ollama) ollama run "$model" ;;
    codex|opencode|claude|droid) ollama launch "$app" --model "$model" ;;
    vscode)
      info "Configuring VS Code integration..."
      ollama launch vscode
      warn "VS Code integration configured. Launch VS Code manually and select Ollama provider in Copilot settings."
      ;;
    *) error "Unknown launch target: $app"; return 1 ;;
  esac
}

# ==============================
# LOAD CONFIG
# ==============================MODEL=""
APP=""
LAST_MODEL=""
LAST_APP=""
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE" 2>/dev/null || true
fi

# ==============================
# INIT
# ==============================
install_base_deps
install_ollama
start_ollama

# ==============================
# LEGAL DISCLAIMER (Runtime Notice)
# ==============================
show_legal_notice() {
  printf "\n${YELLOW}${BOLD}⚠️  Legal Notice${RESET}\n" >&2
  printf "${YELLOW}This is an UNOFFICIAL tool. Not affiliated with Ollama, Anthropic, OpenAI, or others.${RESET}\n" >&2
  printf "${YELLOW}Use at your own risk. You are responsible for compliance with all third-party terms.${RESET}\n" >&2
  printf "${YELLOW}See DISCLAIMER.md and LICENSE for full details.${RESET}\n" >&2
  printf "\n" >&2

  local ack_file="$HOME/.ollama_launcher_ack"
  if [ ! -f "$ack_file" ]; then
    if ask "Do you acknowledge the legal disclaimer and accept all risks?"; then
      touch "$ack_file"
    else
      warn "Acknowledgment required. Exiting."
      exit 1
    fi
  fi
}
show_legal_notice

# ==============================
# MAIN MENU
# ==============================
MAIN_OPTIONS=("Quick Start" "Change Model/App" "Exit")
MAIN_CATEGORIES=("action" "action" "action")

MENU_RESULT_FILE=$(mktemp)

menu_select "=== Ollama Launcher ===" MAIN_OPTIONS MAIN_CATEGORIES
main_choice=$(cat "$MENU_RESULT_FILE" 2>/dev/null || echo "2")

[[ "$main_choice" == "2" ]] && exit 0
# ==============================
# MODEL SELECTION
# ==============================
if [[ "$main_choice" == "1" || -z "${LAST_MODEL:-}" ]]; then
  menu_select "=== Select Model ===" MODELS MODEL_CATEGORIES_INDEX
  MODEL="${MODELS[$(cat "$MENU_RESULT_FILE" 2>/dev/null || echo 0)]}"
else
  MODEL="$LAST_MODEL"
fi

# Fallback safety for set -u
if [ -z "${MODEL:-}" ]; then
  MODEL="${MODELS[0]}"
  warn "Model selection failed. Defaulting to: $MODEL"
fi

if is_cloud_model "$MODEL"; then
  verify_ollama_cloud_auth || exit 1
fi

ensure_model "$MODEL" || exit 1

# ==============================
# APP SELECTION
# ==============================
if [[ "$main_choice" == "1" || -z "${LAST_APP:-}" ]]; then
  menu_select "=== Select App ===" APPS APP_CATEGORIES_INDEX
  APP="${APPS[$(cat "$MENU_RESULT_FILE" 2>/dev/null || echo 0)]}"
else
  APP="$LAST_APP"
fi

if [ -z "${APP:-}" ]; then
  APP="ollama"
  warn "App selection failed. Defaulting to: $APP"
fi

ensure_app "$APP" || exit 1

# ==============================
# SAVE CONFIG
# ==============================
mkdir -p "$(dirname "$CONFIG_FILE")"
cat > "$CONFIG_FILE" <<EOF
LAST_MODEL="$MODEL"
LAST_APP="$APP"
EOF

# ==============================# HEALTH CHECK
# ==============================
if ! curl -s --connect-timeout 3 http://localhost:11434/api/tags >/dev/null 2>&1; then
  warn "Ollama server unresponsive; attempting restart..."
  pkill ollama 2>/dev/null || true
  sleep 2
  ollama serve >/dev/null 2>&1 &
  sleep 3
fi

# ==============================
# LAUNCH
# ==============================
printf "\033c"
printf "\n${GREEN}${BOLD}✓ Launch Ready${RESET}\n"
printf "  ${CYAN}App${RESET}   : %s\n" "${APP:-unknown}"
printf "  ${CYAN}Model${RESET} : %s\n" "${MODEL:-unknown}"
printf "  ${YELLOW}Tip${RESET}   : Press ${BOLD}Ctrl+C${RESET} to terminate session\n\n"

launch_app "${APP:-ollama}" "${MODEL:-}"

echo -e "\n${GREEN}Session ended${RESET}"
exit 0