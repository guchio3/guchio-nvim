#!/bin/bash

# ユーザー実行時の環境設定
if [ "$HOME" != "/root" ]; then
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
fi

# Neovimを起動
exec nvim "$@"
