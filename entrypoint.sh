#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/home/node}"
export CLAWDBOT_GATEWAY_BIND="${CLAWDBOT_GATEWAY_BIND:-lan}"
export CLAWDBOT_GATEWAY_PORT="${CLAWDBOT_GATEWAY_PORT:-${PORT:-18789}}"
export CLAWDBOT_BRIDGE_PORT="${CLAWDBOT_BRIDGE_PORT:-18790}"
export CLAWDBOT_STATE_DIR="${CLAWDBOT_STATE_DIR:-$HOME/.clawdbot}"
export CLAWDBOT_WORKSPACE_DIR="${CLAWDBOT_WORKSPACE_DIR:-$HOME/clawd}"
export CLAWDBOT_CONFIG_PATH="${CLAWDBOT_CONFIG_PATH:-$CLAWDBOT_STATE_DIR/clawdbot.json}"

mkdir -p "$CLAWDBOT_STATE_DIR" "$CLAWDBOT_WORKSPACE_DIR"

if [[ -z "${CLAWDBOT_GATEWAY_TOKEN:-}" ]]; then
  CLAWDBOT_GATEWAY_TOKEN="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
  export CLAWDBOT_GATEWAY_TOKEN
fi

anthropic_key="${CLAWDBOT_ANTHROPIC_API_KEY:-${ANTHROPIC_API_KEY:-}}"
openai_key="${CLAWDBOT_OPENAI_API_KEY:-${OPENAI_API_KEY:-}}"
openrouter_key="${CLAWDBOT_OPENROUTER_API_KEY:-${OPENROUTER_API_KEY:-}}"
ai_gateway_key="${CLAWDBOT_AI_GATEWAY_API_KEY:-${AI_GATEWAY_API_KEY:-}}"
moonshot_key="${CLAWDBOT_MOONSHOT_API_KEY:-${MOONSHOT_API_KEY:-}}"
gemini_key="${CLAWDBOT_GEMINI_API_KEY:-${GEMINI_API_KEY:-}}"
zai_key="${CLAWDBOT_ZAI_API_KEY:-${ZAI_API_KEY:-}}"
minimax_key="${CLAWDBOT_MINIMAX_API_KEY:-${MINIMAX_API_KEY:-}}"
synthetic_key="${CLAWDBOT_SYNTHETIC_API_KEY:-${SYNTHETIC_API_KEY:-}}"
opencode_key="${CLAWDBOT_OPENCODE_ZEN_API_KEY:-${OPENCODE_ZEN_API_KEY:-${OPENCODE_API_KEY:-}}}"
token_provider="${CLAWDBOT_TOKEN_PROVIDER:-}"
token_value="${CLAWDBOT_TOKEN:-}"
require_provider="${CLAWDBOT_REQUIRE_PROVIDER:-1}"

print_dashboard_url() {
  if [[ -f "$CLAWDBOT_CONFIG_PATH" ]]; then
    echo "==> Control UI"
    # Print tokenized dashboard URL without trying to open a browser.
    node dist/index.js dashboard --no-open || true
  fi
}

start_setup_guide() {
  export CLAWDBOT_MISSING_REASON="${CLAWDBOT_MISSING_REASON:-$1}"
  echo "==> Setup required: ${CLAWDBOT_MISSING_REASON}"
  exec node /usr/local/bin/guide-server.js
}

if [[ "${CLAWDBOT_FORCE_ONBOARD:-0}" == "1" || ! -f "$CLAWDBOT_CONFIG_PATH" ]]; then
  auth_choice="${CLAWDBOT_AUTH_CHOICE:-}"
  if [[ -z "$auth_choice" ]]; then
    if [[ -n "$anthropic_key" ]]; then
      auth_choice="anthropic-api-key"
    elif [[ -n "$openai_key" ]]; then
      auth_choice="openai-api-key"
    elif [[ -n "$openrouter_key" ]]; then
      auth_choice="openrouter-api-key"
    elif [[ -n "$ai_gateway_key" ]]; then
      auth_choice="ai-gateway-api-key"
    elif [[ -n "$moonshot_key" ]]; then
      auth_choice="moonshot-api-key"
    elif [[ -n "$gemini_key" ]]; then
      auth_choice="gemini-api-key"
    elif [[ -n "$zai_key" ]]; then
      auth_choice="zai-api-key"
    elif [[ -n "$minimax_key" ]]; then
      auth_choice="minimax-api-key"
    elif [[ -n "$synthetic_key" ]]; then
      auth_choice="synthetic-api-key"
    elif [[ -n "$opencode_key" ]]; then
      auth_choice="opencode-zen"
    elif [[ -n "$token_provider" && -n "$token_value" ]]; then
      auth_choice="token"
    else
      auth_choice="skip"
    fi
  fi

  if [[ "$require_provider" != "0" && "$auth_choice" == "skip" ]]; then
    start_setup_guide "No provider key found in environment"
  fi

  cmd=(
    node dist/index.js onboard
    --non-interactive
    --accept-risk
    --mode local
    --workspace "$CLAWDBOT_WORKSPACE_DIR"
    --gateway-bind "$CLAWDBOT_GATEWAY_BIND"
    --gateway-port "$CLAWDBOT_GATEWAY_PORT"
    --gateway-token "$CLAWDBOT_GATEWAY_TOKEN"
    --auth-choice "$auth_choice"
  )

  if [[ "${CLAWDBOT_SKIP_HEALTH:-1}" != "0" ]]; then
    cmd+=(--skip-health)
  fi
  if [[ "${CLAWDBOT_SKIP_UI:-1}" != "0" ]]; then
    cmd+=(--skip-ui)
  fi
  if [[ "${CLAWDBOT_SKIP_CHANNELS:-1}" != "0" ]]; then
    cmd+=(--skip-channels)
  fi
  if [[ "${CLAWDBOT_SKIP_SKILLS:-0}" != "0" ]]; then
    cmd+=(--skip-skills)
  fi

  case "$auth_choice" in
    anthropic-api-key)
      if [[ -z "$anthropic_key" ]]; then
        start_setup_guide "Missing Anthropic API key for CLAWDBOT_AUTH_CHOICE=anthropic-api-key"
      fi
      cmd+=(--anthropic-api-key "$anthropic_key")
      ;;
    openai-api-key)
      if [[ -z "$openai_key" ]]; then
        start_setup_guide "Missing OpenAI API key for CLAWDBOT_AUTH_CHOICE=openai-api-key"
      fi
      cmd+=(--openai-api-key "$openai_key")
      ;;
    openrouter-api-key)
      if [[ -z "$openrouter_key" ]]; then
        start_setup_guide "Missing OpenRouter API key for CLAWDBOT_AUTH_CHOICE=openrouter-api-key"
      fi
      cmd+=(--openrouter-api-key "$openrouter_key")
      ;;
    ai-gateway-api-key)
      if [[ -z "$ai_gateway_key" ]]; then
        start_setup_guide "Missing AI Gateway API key for CLAWDBOT_AUTH_CHOICE=ai-gateway-api-key"
      fi
      cmd+=(--ai-gateway-api-key "$ai_gateway_key")
      ;;
    moonshot-api-key)
      if [[ -z "$moonshot_key" ]]; then
        start_setup_guide "Missing Moonshot API key for CLAWDBOT_AUTH_CHOICE=moonshot-api-key"
      fi
      cmd+=(--moonshot-api-key "$moonshot_key")
      ;;
    gemini-api-key)
      if [[ -z "$gemini_key" ]]; then
        start_setup_guide "Missing Gemini API key for CLAWDBOT_AUTH_CHOICE=gemini-api-key"
      fi
      cmd+=(--gemini-api-key "$gemini_key")
      ;;
    zai-api-key)
      if [[ -z "$zai_key" ]]; then
        start_setup_guide "Missing Z.AI API key for CLAWDBOT_AUTH_CHOICE=zai-api-key"
      fi
      cmd+=(--zai-api-key "$zai_key")
      ;;
    minimax-api-key)
      if [[ -z "$minimax_key" ]]; then
        start_setup_guide "Missing MiniMax API key for CLAWDBOT_AUTH_CHOICE=minimax-api-key"
      fi
      cmd+=(--minimax-api-key "$minimax_key")
      ;;
    synthetic-api-key)
      if [[ -z "$synthetic_key" ]]; then
        start_setup_guide "Missing Synthetic API key for CLAWDBOT_AUTH_CHOICE=synthetic-api-key"
      fi
      cmd+=(--synthetic-api-key "$synthetic_key")
      ;;
    opencode-zen)
      if [[ -z "$opencode_key" ]]; then
        start_setup_guide "Missing OpenCode Zen API key for CLAWDBOT_AUTH_CHOICE=opencode-zen"
      fi
      cmd+=(--opencode-zen-api-key "$opencode_key")
      ;;
    token)
      if [[ -z "$token_provider" || -z "$token_value" ]]; then
        start_setup_guide "Missing CLAWDBOT_TOKEN_PROVIDER or CLAWDBOT_TOKEN for CLAWDBOT_AUTH_CHOICE=token"
      fi
      cmd+=(--token-provider "$token_provider" --token "$token_value")
      ;;
    skip)
      if [[ "$require_provider" != "0" ]]; then
        start_setup_guide "Provider key required"
      fi
      ;;
    *)
      start_setup_guide "Unsupported CLAWDBOT_AUTH_CHOICE: $auth_choice"
      ;;
  esac

  echo "==> Running clawd.bot onboarding (non-interactive)"
  "${cmd[@]}"
  print_dashboard_url
fi

if [[ "${CLAWDBOT_PRINT_DASHBOARD_URL:-1}" != "0" ]]; then
  print_dashboard_url
fi

exec node dist/index.js gateway-daemon --bind "$CLAWDBOT_GATEWAY_BIND" --port "$CLAWDBOT_GATEWAY_PORT"
