# Optimized Dockerfile with multi-stage builds and better caching
FROM ubuntu:24.04 AS base

# Environment setup (rarely changes)
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:ja" \
    LC_ALL="en_US.UTF-8" \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    XDG_CONFIG_HOME=/root/.config \
    XDG_DATA_HOME=/root/.local/share \
    XDG_STATE_HOME=/root/.local/state \
    XDG_CACHE_HOME=/root/.cache

# ===== Stage 1: System dependencies (cached well) =====
FROM base AS system-deps

# Install all system packages in one layer for better caching
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Base tools
        locales ca-certificates curl git wget \
        # Build tools
        gcc g++ make build-essential \
        libxml2-dev libxslt-dev musl-dev \
        # Python
        python3-dev python3-pip python3-venv python-is-python3 \
        # Languages
        golang nodejs npm \
        # Neovim and tools
        software-properties-common \
        && \
    # Add Neovim PPA
    apt-add-repository -y ppa:neovim-ppa/unstable && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        neovim ripgrep fd-find \
        && \
    # Locale setup
    locale-gen en_US.UTF-8 && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ===== Stage 2: Language tools (changes more frequently) =====
FROM system-deps AS lang-tools

# Upgrade Node.js
RUN npm install -g n && \
    n stable && \
    hash -r && \
    npm install -g dockerfile-language-server-nodejs && \
    # Clean up old node
    apt-get purge -y nodejs npm && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /root/.npm

# Install uv for Python
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Python packages
RUN uv pip install --system --break-system-packages \
    msgpack pynvim isort black mypy ruff

# Go tools
RUN go install golang.org/x/tools/gopls@latest
ENV PATH="$PATH:/root/go/bin"

# ===== Stage 3: Neovim configuration (changes most frequently) =====
FROM lang-tools AS nvim-setup

# Copy configuration files first (for better cache invalidation)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy Neovim config
COPY nvim /root/.config/nvim

# Create necessary directories
RUN mkdir -p /root/.local/state/nvim/shada \
             /root/.local/share/nvim \
             /root/.cache/nvim && \
    touch /root/.local/share/nvim/telescope_history && \
    chmod -R 755 /root/.config && \
    chmod -R 777 /root/.cache /root/.local/state /root/.local/share && \
    chmod 755 /root

# Install all Neovim plugins in one go
ENV DOCKER_BUILD=1
RUN nvim --headless "+Lazy! sync" +qa 2>/dev/null || true && \
    nvim --headless -c "TSUpdateSync" +qa 2>/dev/null || true && \
    nvim --headless \
        -c "MasonInstall lua-language-server pyright gopls rust-analyzer typescript-language-server" \
        -c "MasonInstall dockerfile-language-server yaml-language-server json-lsp bash-language-server ruff" \
        -c "MasonInstall gofumpt golangci-lint prettier stylua shellcheck shfmt" \
        +qa 2>/dev/null || true && \
    # Clear build-time environment variable
    true
ENV DOCKER_BUILD=

# Final cleanup
RUN rm -rf /tmp/* /var/tmp/* ~/.cache/pip

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]