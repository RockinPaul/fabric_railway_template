#!/usr/bin/env sh
# Seed Fabric's config directory, translate Railway variables into its .env,
# then hand off to the server as an unprivileged user.
#
# Fabric reads providers and defaults from ~/.config/fabric/.env rather than
# from the process environment, so anything set on the service has to be written
# into that file before the server starts.
set -eu

CONFIG_DIR="${FABRIC_CONFIG_DIR:-/home/appuser/.config/fabric}"
APP_DATA_DIR="${FABRIC_APP_DATA_DIR:-/usr/local/share/fabric}"
PORT="${PORT:-8080}"
export HOME="${HOME:-/home/appuser}"

# Upstream refuses to bind a non-loopback address without an API key, which is
# the right behaviour but produces a terse error. Say why first.
if [ -z "${FABRIC_API_KEY:-}" ]; then
  echo "FABRIC_API_KEY is empty." >&2
  echo "Fabric will not expose its API on a public address without one, and it" >&2
  echo "should not: the API spends whatever provider credits you configure." >&2
  echo "Set FABRIC_API_KEY to a long random value and send it as X-API-Key." >&2
  exit 1
fi

mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/patterns" "$CONFIG_DIR/strategies" \
         "$CONFIG_DIR/contexts" "$CONFIG_DIR/sessions"
touch "$CONFIG_DIR/.env"

# Copy the baked patterns and strategies in once, guarded by a marker so a
# deployer's own edits are never overwritten on a later boot.
copy_seed_data() {
  source_dir="$1"
  target_dir="$2"
  marker="$3"

  if [ -d "$source_dir" ] && [ ! -e "$marker" ]; then
    cp -R "$source_dir"/. "$target_dir"/
    touch "$marker"
  fi
}

copy_seed_data "$APP_DATA_DIR/patterns" "$CONFIG_DIR/patterns" "$CONFIG_DIR/patterns/loaded"
copy_seed_data "$APP_DATA_DIR/strategies" "$CONFIG_DIR/strategies" "$CONFIG_DIR/strategies/.loaded"

if [ ! -f "$CONFIG_DIR/unique_patterns.txt" ]; then
  : > "$CONFIG_DIR/unique_patterns.txt.tmp"
  for pattern_dir in "$CONFIG_DIR"/patterns/*; do
    [ -d "$pattern_dir" ] || continue
    basename "$pattern_dir" >> "$CONFIG_DIR/unique_patterns.txt.tmp"
  done
  sort "$CONFIG_DIR/unique_patterns.txt.tmp" > "$CONFIG_DIR/unique_patterns.txt"
  rm -f "$CONFIG_DIR/unique_patterns.txt.tmp"
fi

# Rewrite rather than sed in place: an API key or base URL containing a
# backslash or slash would corrupt a sed expression.
set_env() {
  key="$1"
  value="${2:-}"

  [ -n "$value" ] || return 0

  if [ -s "$CONFIG_DIR/.env" ]; then
    grep -v "^${key}=" "$CONFIG_DIR/.env" > "$CONFIG_DIR/.env.tmp" || true
  else
    : > "$CONFIG_DIR/.env.tmp"
  fi
  printf '%s=%s\n' "$key" "$value" >> "$CONFIG_DIR/.env.tmp"
  mv "$CONFIG_DIR/.env.tmp" "$CONFIG_DIR/.env"
}

set_env DEFAULT_VENDOR "${DEFAULT_VENDOR:-OpenAI}"
set_env DEFAULT_MODEL "${DEFAULT_MODEL:-gpt-4.1-mini}"
set_env DEFAULT_MODEL_CONTEXT_LENGTH "${DEFAULT_MODEL_CONTEXT_LENGTH:-}"
set_env PATTERNS_LOADER_GIT_REPO_URL "${PATTERNS_LOADER_GIT_REPO_URL:-https://github.com/danielmiessler/fabric.git}"
set_env PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER "${PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER:-data/patterns}"
set_env PROMPT_STRATEGIES_GIT_REPO_URL "${PROMPT_STRATEGIES_GIT_REPO_URL:-https://github.com/danielmiessler/fabric.git}"
set_env PROMPT_STRATEGIES_GIT_REPO_STRATEGIES_FOLDER "${PROMPT_STRATEGIES_GIT_REPO_STRATEGIES_FOLDER:-data/strategies}"

PROVIDER_KEYS="OPENAI_API_KEY ANTHROPIC_API_KEY GEMINI_API_KEY GOOGLE_API_KEY
GROQ_API_KEY MISTRAL_API_KEY OPENROUTER_API_KEY DEEPSEEK_API_KEY SILICON_API_KEY
GROKAI_API_KEY BEDROCK_API_KEY BEDROCK_ACCESS_KEY AZURE_API_KEY
AZUREAIGATEWAY_SUBSCRIPTION_KEY VERTEXAI_PROJECT_ID OLLAMA_URL
LM_STUDIO_API_BASE_URL"

for key in \
  OPENAI_API_KEY OPENAI_API_BASE_URL \
  ANTHROPIC_API_KEY ANTHROPIC_API_BASE_URL \
  GEMINI_API_KEY GOOGLE_API_KEY \
  GROQ_API_KEY GROQ_API_BASE_URL \
  MISTRAL_API_KEY MISTRAL_API_BASE_URL \
  OPENROUTER_API_KEY OPENROUTER_API_BASE_URL \
  DEEPSEEK_API_KEY DEEPSEEK_API_BASE_URL \
  SILICON_API_KEY SILICON_API_BASE_URL \
  GROKAI_API_KEY GROKAI_API_BASE_URL \
  OLLAMA_URL LM_STUDIO_API_BASE_URL \
  JINA_API_KEY YOUTUBE_API_KEY \
  SPOTIFY_CLIENT_ID SPOTIFY_CLIENT_SECRET \
  BEDROCK_REGION BEDROCK_API_KEY BEDROCK_ACCESS_KEY BEDROCK_SECRET_KEY \
  VERTEXAI_PROJECT_ID VERTEXAI_REGION \
  AZURE_API_KEY AZURE_API_BASE_URL AZURE_API_VERSION \
  AZUREAIGATEWAY_BACKEND AZUREAIGATEWAY_GATEWAY_URL AZUREAIGATEWAY_SUBSCRIPTION_KEY AZUREAIGATEWAY_API_VERSION \
  LANGUAGE_OUTPUT CUSTOM_PATTERNS_DIRECTORY; do
  eval "value=\${$key:-}"
  set_env "$key" "$value"
done

# No provider credential means the server starts and answers /health, but every
# completion fails. Warn loudly rather than refuse: a deployer may be adding
# keys after the first deploy, or pointing at a keyless local model.
configured_provider=""
for key in $PROVIDER_KEYS; do
  eval "value=\${$key:-}"
  if [ -n "$value" ]; then
    configured_provider="$key"
    break
  fi
done
if [ -n "$configured_provider" ]; then
  echo "provider credential found: $configured_provider"
else
  echo "WARNING: no provider credential is set, so every completion will fail." >&2
  echo "Set one that matches DEFAULT_VENDOR, for example OPENAI_API_KEY," >&2
  echo "ANTHROPIC_API_KEY, GEMINI_API_KEY or OPENROUTER_API_KEY, then redeploy." >&2
fi

chown -R appuser:appuser "$CONFIG_DIR"

# ":$PORT" listens on the IPv6 wildcard as a dual-stack socket, which is what
# Railway's private network needs and its public edge still reaches over IPv4.
exec su-exec appuser /usr/local/bin/fabric --serve --address=":${PORT}" --api-key="${FABRIC_API_KEY}"
