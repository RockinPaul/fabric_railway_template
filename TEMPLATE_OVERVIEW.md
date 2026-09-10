# Deploy and Host Fabric on Railway

[Fabric](https://github.com/danielmiessler/fabric) is an open-source framework for augmenting work with AI through reusable prompts called patterns. This template deploys Fabric as a hosted REST API, so apps, automations, and agents can call Fabric patterns, chat completions, model discovery, sessions, contexts, and helper tools over HTTP.

## About Hosting Fabric

This Railway template builds Fabric from source using a custom Dockerfile, starts the Fabric REST API, and exposes it behind a Railway public domain. It includes bundled Fabric patterns and strategies, Swagger API docs, `/health` health checks, and API-key protection through the `X-API-Key` header. `FABRIC_API_KEY` is preconfigured by the template as `${{ secret(32) }}`, so Railway generates a strong API secret automatically. For persistent usage, attach or keep the Railway volume at `/home/appuser/.config/fabric`; this keeps config, sessions, contexts, patterns, and strategies across redeploys. Before first use, set `DEFAULT_VENDOR`, `DEFAULT_MODEL`, and one provider API key such as `OPENROUTER_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `GEMINI_API_KEY`.

## Common Use Cases

- Run Fabric patterns from apps, agents, scripts, or workflow automations.
- Host a reusable AI prompt API for summarization, extraction, analysis, and text transformation.
- Deploy one Fabric endpoint that can use OpenRouter, OpenAI, Anthropic, Gemini, and many other providers.

## Dependencies for Fabric Hosting

- Railway account and project.
- `FABRIC_API_KEY`, generated automatically by the template with `${{ secret(32) }}`.
- One AI provider API key matching `DEFAULT_VENDOR`.
- Required user-selected variables: `DEFAULT_VENDOR`, `DEFAULT_MODEL`, and the matching provider key.
- Railway volume mounted at `/home/appuser/.config/fabric`.
- Public Railway domain for external API access.

## Provider Variable Options

`DEFAULT_VENDOR` should use one of these provider names. Set only the matching
credential variables for the provider you choose.

OpenAI-compatible providers:

| `DEFAULT_VENDOR` | Required variables | Optional variables |
| --- | --- | --- |
| `Abacus` | `ABACUS_API_KEY` | `ABACUS_API_BASE_URL` |
| `AIML` | `AIML_API_KEY` | `AIML_API_BASE_URL` |
| `Cerebras` | `CEREBRAS_API_KEY` | `CEREBRAS_API_BASE_URL` |
| `DeepSeek` | `DEEPSEEK_API_KEY` | `DEEPSEEK_API_BASE_URL` |
| `GitHub` | `GITHUB_API_KEY` | `GITHUB_API_BASE_URL` |
| `GrokAI` | `GROKAI_API_KEY` | `GROKAI_API_BASE_URL` |
| `Groq` | `GROQ_API_KEY` | `GROQ_API_BASE_URL` |
| `Infermatic` | `INFERMATIC_API_KEY` | `INFERMATIC_API_BASE_URL` |
| `Langdock` | `LANGDOCK_API_KEY` | `LANGDOCK_API_BASE_URL`, `LANGDOCK_REGION` |
| `LiteLLM` | `LITELLM_API_KEY` | `LITELLM_API_BASE_URL` |
| `Mammouth` | `MAMMOUTH_API_KEY` | `MAMMOUTH_API_BASE_URL` |
| `MiniMax` | `MINIMAX_API_KEY` | `MINIMAX_API_BASE_URL` |
| `Mistral` | `MISTRAL_API_KEY` | `MISTRAL_API_BASE_URL` |
| `Novita AI` | `NOVITA_AI_API_KEY` | `NOVITA_AI_API_BASE_URL` |
| `OpenRouter` | `OPENROUTER_API_KEY` | `OPENROUTER_API_BASE_URL` |
| `SiliconCloud` | `SILICONCLOUD_API_KEY` | `SILICONCLOUD_API_BASE_URL` |
| `Together` | `TOGETHER_API_KEY` | `TOGETHER_API_BASE_URL` |
| `Venice AI` | `VENICE_AI_API_KEY` | `VENICE_AI_API_BASE_URL` |
| `Z AI` | `Z_AI_API_KEY` | `Z_AI_API_BASE_URL` |

Native and special providers:

| `DEFAULT_VENDOR` | Required variables | Optional variables |
| --- | --- | --- |
| `Anthropic` | `ANTHROPIC_API_KEY` | `ANTHROPIC_API_BASE_URL` |
| `Azure` | `AZURE_API_KEY`, `AZURE_API_BASE_URL`, `AZURE_DEPLOYMENTS` | `AZURE_API_VERSION` |
| `AzureAIGateway` | `AZUREAIGATEWAY_BACKEND`, `AZUREAIGATEWAY_GATEWAY_URL`, `AZUREAIGATEWAY_SUBSCRIPTION_KEY` | `AZUREAIGATEWAY_API_VERSION` |
| `AzureEntra` | `AZUREENTRA_API_BASE_URL`, `AZUREENTRA_DEPLOYMENTS` | `AZUREENTRA_API_VERSION`; also provide Azure identity env such as `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID` |
| `Bedrock` | `BEDROCK_AWS_REGION` | `BEDROCK_API_KEY`, `BEDROCK_AWS_ACCESS_KEY_ID`, `BEDROCK_AWS_SECRET_ACCESS_KEY`; AWS credential-chain env also works |
| `Codex` | `CODEX_REFRESH_TOKEN`, `CODEX_ACCOUNT_ID` | `CODEX_ACCESS_TOKEN`, `CODEX_BASE_URL`, `CODEX_AUTH_BASE_URL` |
| `Copilot` | `COPILOT_TENANT_ID`, `COPILOT_CLIENT_ID`, plus either `COPILOT_ACCESS_TOKEN` or `COPILOT_REFRESH_TOKEN` with `COPILOT_CLIENT_SECRET` | `COPILOT_API_BASE_URL`, `COPILOT_TIME_ZONE` |
| `DigitalOcean` | `DIGITALOCEAN_INFERENCE_KEY` | `DIGITALOCEAN_INFERENCE_BASE_URL`, `DIGITALOCEAN_TOKEN` |
| `Exolab` | `EXOLAB_API_BASE_URL`, `EXOLAB_MODELS` | `EXOLAB_API_KEY` |
| `Gemini` | `GEMINI_API_KEY` | None |
| `LM Studio` | `LM_STUDIO_API_URL` | `LM_STUDIO_API_KEY` |
| `Ollama` | `OLLAMA_API_URL` | `OLLAMA_API_KEY`, `OLLAMA_HTTP_TIMEOUT` |
| `OpenAI` | `OPENAI_API_KEY` | `OPENAI_API_BASE_URL` |
| `Perplexity` | `PERPLEXITY_API_KEY` | None |
| `VertexAI` | `VERTEXAI_PROJECT_ID` | `VERTEXAI_REGION`; also provide Google Application Default Credentials such as `GOOGLE_APPLICATION_CREDENTIALS` |

## Other Runtime Options

| Variable | Default | Description |
| --- | --- | --- |
| `DEFAULT_MODEL_CONTEXT_LENGTH` | empty | Optional context length override for the default model. |
| `PORT` | Railway-provided | HTTP port. Railway injects this automatically. |
| `FABRIC_CONFIG_DIR` | `/home/appuser/.config/fabric` | Runtime config directory. Keep this aligned with the Railway volume mount. |
| `FABRIC_APP_DATA_DIR` | `/usr/local/share/fabric` | Read-only bundled seed data directory inside the image. |
| `PATTERNS_LOADER_GIT_REPO_URL` | `https://github.com/danielmiessler/fabric.git` | Source repo for pattern loading. |
| `PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER` | `data/patterns` | Pattern folder inside the source repo. |
| `PROMPT_STRATEGIES_GIT_REPO_URL` | `https://github.com/danielmiessler/fabric.git` | Source repo for prompt strategies. |
| `PROMPT_STRATEGIES_GIT_REPO_STRATEGIES_FOLDER` | `data/strategies` | Strategy folder inside the source repo. |
| `CUSTOM_PATTERNS_DIRECTORY` | empty | Extra directory for custom Fabric patterns. |
| `LANGUAGE_OUTPUT` | empty | Optional default language output hint. |
| `JINA_AI_API_KEY` | empty | Optional Jina API key for web extraction helpers. |
| `YOUTUBE_API_KEY` | empty | Optional YouTube API key for metadata and comments. |
| `SPOTIFY_CLIENT_ID` | empty | Optional Spotify integration client ID. |
| `SPOTIFY_CLIENT_SECRET` | empty | Optional Spotify integration client secret. |

### Deployment Dependencies

- Original Fabric repository: https://github.com/danielmiessler/fabric
- Railway template source repository: https://github.com/RockinPaul/fabric_railway_template
- Railway template deployment docs: https://docs.railway.com/templates/deploy
- OpenRouter API keys: https://openrouter.ai/docs/api-keys
- OpenAI API keys: https://platform.openai.com/docs/api-reference/authentication/api-keys
- Anthropic API getting started: https://docs.anthropic.com/en/api/getting-started
- Gemini API keys: https://ai.google.dev/gemini-api/docs/api-key

### Implementation Details

The template repository is **not** a fork of Fabric. It holds only the Railway
glue: a Dockerfile, an entrypoint and one patch file. The Dockerfile clones a
pinned upstream tag, asserts the tag's commit so a moved tag fails the build,
applies the patch and compiles the binary. Bumping Fabric is a two-line change.

The patch carries three small changes upstream has not taken: an
unauthenticated `/health` route for the platform health check, the correct
`text/event-stream` media type on the streaming chat endpoint, and a CORS
origin read from `FABRIC_ALLOWED_ORIGIN` instead of being pinned to a local
development server.

Patterns and strategies are baked into the image and copied into the volume on
first boot, so a fresh deployment works without reaching out to GitHub. The
copy is guarded by a marker file, so your own edits survive later boots.

Template-provided secret:

```env
FABRIC_API_KEY=${{ secret(32) }}
```

Recommended first-deploy variables:

```env
DEFAULT_VENDOR=OpenRouter
DEFAULT_MODEL=openai/gpt-4.1-mini
OPENROUTER_API_KEY=
```

OpenAI example:

```env
DEFAULT_VENDOR=OpenAI
DEFAULT_MODEL=gpt-4.1-mini
OPENAI_API_KEY=
```

After deploy:

```bash
curl https://YOUR-FABRIC-DOMAIN/health
curl -H "X-API-Key: $FABRIC_API_KEY" https://YOUR-FABRIC-DOMAIN/models/names
curl -H "X-API-Key: $FABRIC_API_KEY" https://YOUR-FABRIC-DOMAIN/patterns/names
```

Set `FABRIC_ALLOWED_ORIGIN` if a browser application will read the streaming
chat endpoint; it defaults to `*`, which is safe here because the API
authenticates with a header rather than cookies.

Swagger is available at:

```text
https://YOUR-FABRIC-DOMAIN/swagger/index.html
```

## Why Deploy Fabric on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Fabric on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
