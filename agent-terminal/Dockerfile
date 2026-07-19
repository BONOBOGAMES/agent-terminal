ARG BUILD_FROM
FROM ${BUILD_FROM}

# All runtime packages are baked into the image so startup never depends on
# the network (ttyd/tmux/jq were previously apk-installed on every boot in CT)
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    nano \
    nodejs \
    npm \
    py3-aiohttp \
    py3-beautifulsoup4 \
    py3-pip \
    py3-requests \
    py3-yaml \
    python3 \
    tmux \
    tree \
    ttyd \
    vim \
    wget \
    yq

# uv from PyPI, pinned: Alpine 3.21's apk uv (0.5.x) cannot install managed
# musl CPython builds, which ha-mcp >= 4.x needs (it requires Python 3.13;
# Alpine 3.21 ships 3.12). musllinux wheels exist for amd64/aarch64.
RUN pip3 install --no-cache-dir --break-system-packages uv==0.11.28

# Keep the npm cache out of persistent storage so it never lands in HA backups
ENV npm_config_cache=/tmp/npm-cache

# Disposable-container marker (harmless for Grok; retained for parity with CT)
ENV IS_SANDBOX=1

# Bundled Grok Build CLI. Frozen at image build time; when grok_auto_update is
# enabled, run.sh maintains a persistent install under /data that takes
# precedence and keeps itself current.
# Official install publishes static-pie linux-{x86_64,aarch64} binaries.
ENV GROK_BIN_DIR=/usr/local/bin
RUN curl -fsSL https://x.ai/cli/install.sh | bash \
    && command -v grok \
    && grok --version

WORKDIR /config

COPY run.sh /run.sh
COPY scripts/ /opt/scripts/
RUN chmod +x /run.sh /opt/scripts/*.sh

# Use exec form for better signal handling
CMD ["/run.sh"]
