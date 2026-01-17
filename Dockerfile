FROM node:22-bookworm

ARG CLAWDBOT_REPO="https://github.com/clawdbot/clawdbot"
ARG CLAWDBOT_REF="main"
ARG CLAWDBOT_DOCKER_APT_PACKAGES=""

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
  && rm -rf /var/lib/apt/lists/*

RUN if [ -n "$CLAWDBOT_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $CLAWDBOT_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app
# Allow CLAWDBOT_REF to be a branch, tag, or commit SHA.
RUN git clone --depth 1 "$CLAWDBOT_REPO" . \
  && (git checkout "$CLAWDBOT_REF" || (git fetch --depth 1 origin "$CLAWDBOT_REF" && git checkout "$CLAWDBOT_REF"))

RUN pnpm install --frozen-lockfile
RUN pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV CLAWDBOT_PREFER_PNPM=1
RUN pnpm ui:install
RUN pnpm ui:build

ENV NODE_ENV=production
ENV HOME=/home/node
ENV CLAWDBOT_STATE_DIR=/home/node/.clawdbot
ENV CLAWDBOT_WORKSPACE_DIR=/home/node/clawd

RUN mkdir -p /home/node/.clawdbot /home/node/clawd \
  && chown -R node:node /home/node /app

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY guide-server.js /usr/local/bin/guide-server.js
COPY guide /usr/local/share/clawd-guide
RUN chmod +x /usr/local/bin/entrypoint.sh

USER node
WORKDIR /app

EXPOSE 18789
VOLUME ["/home/node/.clawdbot", "/home/node/clawd"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
