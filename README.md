# clawd.bot Coolify go-live repo

This repo is a thin wrapper that **builds clawd.bot from source** and **auto‑runs non‑interactive onboarding** on first start. It is designed for Coolify: connect the repo, set a few env vars, and the gateway comes up ready to use.

## Quick start (Coolify)

**Recommended (100% automated ports):** Use **Docker Compose** with the included `docker-compose.yaml`.

1) Create a new **Docker Compose** app in Coolify and point it at this repo.
2) Coolify will auto‑map ports **18789** and **18790** from `docker-compose.yaml`.
3) Add at least one model provider key (see below).
4) Deploy.

**Alternative:** Dockerfile app (manual port mapping).
1) Create a new application in Coolify and point it at this repo.
2) Build with the Dockerfile at repo root.
3) Expose port **18789** (gateway) and optionally **18790** (bridge).
4) Add at least one model provider key (see below).
5) Deploy.

When the container starts the first time, it will:
- generate a gateway token (unless you provide one)
- run `clawdbot onboard --non-interactive --accept-risk ...`
- start the gateway daemon
- print a **tokenized Control UI URL** to the logs

If **no provider key** is set, the container serves a **visual setup guide**
on the Coolify URL instead of starting the gateway. Add env vars, redeploy,
and the Control UI will replace the guide.

Open the Control UI at:

```
http://<your-host>:18789/
```

Paste the gateway token shown in logs (or the one you set in env) into Settings → token.

## Required env (pick one provider)

Set **one** of the following auth choices + key (or set `CLAWDBOT_AUTH_CHOICE=skip` and configure later in the UI):

- Anthropic: `CLAWDBOT_AUTH_CHOICE=anthropic-api-key` + `ANTHROPIC_API_KEY`
- OpenAI: `CLAWDBOT_AUTH_CHOICE=openai-api-key` + `OPENAI_API_KEY`
- OpenRouter: `CLAWDBOT_AUTH_CHOICE=openrouter-api-key` + `OPENROUTER_API_KEY`
- Vercel AI Gateway: `CLAWDBOT_AUTH_CHOICE=ai-gateway-api-key` + `AI_GATEWAY_API_KEY`
- Gemini: `CLAWDBOT_AUTH_CHOICE=gemini-api-key` + `GEMINI_API_KEY`
- Z.AI: `CLAWDBOT_AUTH_CHOICE=zai-api-key` + `ZAI_API_KEY`
- Moonshot: `CLAWDBOT_AUTH_CHOICE=moonshot-api-key` + `MOONSHOT_API_KEY`
- MiniMax: `CLAWDBOT_AUTH_CHOICE=minimax-api-key` + `MINIMAX_API_KEY`
- Synthetic: `CLAWDBOT_AUTH_CHOICE=synthetic-api-key` + `SYNTHETIC_API_KEY`
- OpenCode Zen: `CLAWDBOT_AUTH_CHOICE=opencode-zen` + `OPENCODE_API_KEY`
- Generic token: `CLAWDBOT_AUTH_CHOICE=token` + `CLAWDBOT_TOKEN_PROVIDER` + `CLAWDBOT_TOKEN`

If you omit `CLAWDBOT_AUTH_CHOICE`, the entrypoint will auto‑select the first matching key it finds (Anthropic → OpenAI → OpenRouter → AI Gateway → Moonshot → Gemini → Z.AI → MiniMax → Synthetic → OpenCode → token). If none are set, it falls back to `skip`.

## Optional env

- `CLAWDBOT_GATEWAY_TOKEN` — provide your own token (otherwise auto‑generated)
- `CLAWDBOT_GATEWAY_BIND` — default `lan`
- `CLAWDBOT_GATEWAY_PORT` — default `18789`
- `CLAWDBOT_BRIDGE_PORT` — default `18790`
- `CLAWDBOT_STATE_DIR` — default `/home/node/.clawdbot`
- `CLAWDBOT_WORKSPACE_DIR` — default `/home/node/clawd`
- `CLAWDBOT_FORCE_ONBOARD=1` — rerun onboarding even if config exists
- `CLAWDBOT_PRINT_DASHBOARD_URL=1` — print tokenized Control UI URL on startup (set to `0` to disable)
- `CLAWDBOT_SKIP_HEALTH=1` — default (prevents onboarding health check from failing before gateway starts)
- `CLAWDBOT_SKIP_UI=1` — default (no browser/UI prompts)
- `CLAWDBOT_SKIP_CHANNELS=1` — default
- `CLAWDBOT_SKIP_SKILLS=1` — optional (leave unset to keep skills config)
- `CLAWDBOT_REQUIRE_PROVIDER=1` — default. Set to `0` to allow onboarding without a provider key.

## Persistence (recommended)

Mount persistent storage for:
- `/home/node/.clawdbot`
- `/home/node/clawd`

In Coolify, add two volumes mapped to those paths so config and workspace survive redeploys.

## Build/version pinning

You can pin the upstream clawd.bot version with build args:

- `CLAWDBOT_REF` — git ref (tag/branch/commit), default `main`
- `CLAWDBOT_REPO` — alternate repo URL, default `https://github.com/clawdbot/clawdbot`

In Coolify, set these as **build args** if you want a fixed release.

## Upgrades (recommended)

Because this image **builds clawd.bot at build time**, upgrades happen on **rebuild/redeploy**.

### Option A — Manual (simple)
- Click **Redeploy** in Coolify whenever you want to pull latest `CLAWDBOT_REF`.

### Option B — Nightly auto‑redeploy (100% automated)
This repo includes a GitHub Actions workflow that pings the Coolify deploy webhook nightly.

1) In Coolify, copy the **Deploy Webhook** URL for this app.
2) In GitHub → **Settings → Secrets and variables → Actions**, add:
   - `COOLIFY_WEBHOOK_URL` (the deploy webhook URL)
   - `COOLIFY_TOKEN` (your Coolify API token)
3) The workflow runs daily at **04:00 UTC**. Edit `.github/workflows/nightly-redeploy.yml` to change the time.

## Local run

```bash
docker build -t clawd-coolify .

docker run --rm -p 18789:18789 \
  -e CLAWDBOT_AUTH_CHOICE=anthropic-api-key \
  -e ANTHROPIC_API_KEY=your_key \
  clawd-coolify
```

## Notes

- This wrapper repo does **not** vendor clawd.bot source. The Dockerfile clones and builds it at image build time.
- Onboarding runs once per persisted config file (`$CLAWDBOT_STATE_DIR/clawdbot.json`).
