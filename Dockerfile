FROM ubuntu:24.04

# ロケール設定
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# マルチバイト文字をまともに扱うための設定
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:ja" LC_ALL="en_US.UTF-8"

# タイムゾーン設定（非対話的インストール用）
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# neovim は最新版を install (0.10以上が必要)
RUN apt update && apt upgrade -y && \
    apt install -y software-properties-common && \
    apt-add-repository -y ppa:neovim-ppa/unstable && \
    apt update && \
    apt install -y neovim

# 最低限必要なパッケージ
RUN apt install -y \
    curl \
    gcc \
    git \
    wget \
    build-essential \
    libxml2-dev \
    libxslt-dev \
    musl-dev \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    fd-find \
    golang \
    nodejs \
    npm \
    && \
    apt install -y \
    python-is-python3 \
    && \
    npm install n -g \
    && \
    n stable \
    && \
    apt purge -y nodejs npm \
    && \
    rm -rf /var/cache/apt/*

# uv のインストール
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# nvim設定をコピー
COPY nvim /root/.config/nvim

# Dockerビルド時の環境変数を設定
ENV DOCKER_BUILD=1

# lazy.nvimでプラグインをインストール（ヘッドレスモード）
RUN nvim --headless "+Lazy! sync" +qa || true

# TreesitterのParserをインストール（ensure_installedを使用）
RUN nvim --headless -c "TSUpdateSync" +qa || true

# インストール確認
RUN nvim --headless -c "lua print('Treesitter parsers: ' .. #require('nvim-treesitter.info').installed_parsers())" +qa || true

# 環境変数をクリア（実行時には不要）
ENV DOCKER_BUILD=

# Mason でLSPサーバーとツールをインストール
# LSPサーバーとツールを一括インストール（効率化）
RUN nvim --headless \
  -c "MasonInstall lua-language-server pyright gopls rust-analyzer typescript-language-server" \
  -c "MasonInstall dockerfile-language-server yaml-language-server json-lsp bash-language-server ruff" \
  -c "MasonInstall black isort mypy gofumpt golangci-lint prettier stylua shellcheck shfmt" \
  +qa 2>/dev/null || true

# python env (uv を使用、システムパッケージの保護を無視)
RUN uv pip install --system --break-system-packages msgpack pynvim isort black flake8 mypy ruff

# go env
RUN go install golang.org/x/tools/gopls@latest
ENV PATH=$PATH:/root/go/bin

# docker env
RUN npm install -g dockerfile-language-server-nodejs

# XDG Base Directory 環境変数設定（Neovim用）
ENV XDG_CONFIG_HOME=/root/.config
ENV XDG_DATA_HOME=/root/.local/share
ENV XDG_STATE_HOME=/root/.local/state
ENV XDG_CACHE_HOME=/root/.cache

# entrypoint スクリプトをコピー
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 必要なディレクトリを作成して権限設定
RUN mkdir -p /root/.local/state/nvim/shada && \
    mkdir -p /root/.local/share/nvim && \
    touch /root/.local/share/nvim/telescope_history && \
    chmod -R 755 /root/.config && \
    chmod -R 775 /root/.cache /root/.local/state /root/.local/share && \
    chmod 755 /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
