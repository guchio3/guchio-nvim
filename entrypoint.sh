#!/bin/bash

# Disable Neovim log file generation
export NVIM_LOG_FILE="${NVIM_LOG_FILE:-/dev/null}"

# ユーザー実行時の環境設定
if [ "$(id -u)" -ne 0 ]; then
    USER_HOME="$(getent passwd "$(id -u)" | cut -d: -f6)"
    if [ -n "$USER_HOME" ] && [ "$HOME" != "$USER_HOME" ]; then
        export HOME="$USER_HOME"
    fi

    # 設定ファイルへのシンボリックリンクを作成
    mkdir -p "$HOME/.config"
    if [ ! -e "$HOME/.config/nvim" ]; then
        ln -sf /root/.config/nvim "$HOME/.config/nvim"
    fi

    # Masonのデータディレクトリを共有
    mkdir -p "$HOME/.local/share" "$HOME/.local/state"
    if [ ! -e "$HOME/.local/share/nvim" ]; then
        ln -sf /root/.local/share/nvim "$HOME/.local/share/nvim"
    fi
    if [ ! -e "$HOME/.local/state/nvim" ]; then
        ln -sf /root/.local/state/nvim "$HOME/.local/state/nvim"
    fi

    # キャッシュディレクトリを共有
    mkdir -p "$HOME/.cache"
    if [ ! -e "$HOME/.cache/nvim" ]; then
        ln -sf /root/.cache/nvim "$HOME/.cache/nvim"
    fi

    # Goのモジュールキャッシュとビルドディレクトリを設定
    mkdir -p "$HOME/go/pkg/mod" "$HOME/.cache/go-build"
    export GOPATH="$HOME/go"
    export GOMODCACHE="$HOME/go/pkg/mod"
    export GOCACHE="$HOME/.cache/go-build"
    export PATH="$PATH:$GOPATH/bin"
fi

# Neovimを起動
exec nvim "$@"
