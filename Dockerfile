FROM ubuntu:20.04

# マルチバイト文字をまともに扱うための設定
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:ja" LC_ALL="en_US.UTF-8"

# neovim は version を上げて install
RUN apt update && apt upgrade -y && \
    apt install -y software-properties-common && \
    apt-add-repository -y ppa:neovim-ppa/stable && \
    apt update && \
    apt install -y neovim

# 最低限必要なパッケージ
RUN apt install -y \
    curl \
    gcc \
    git \
    libxml2-dev \
    libxslt-dev \
    musl-dev\
    python3-dev \
    python3-pip \
    ripgrep \
    nodejs \
    npm \
    && \
    npm install n -g \
    && \
    n stable \
    && \
    apt purge -y nodejs npm \
    && \
    rm -rf /var/cache/apt/*

RUN pip3 install --upgrade pip msgpack pynvim isort black flake8 mypy

# install dein.vim
COPY nvim /root/.config/nvim
RUN curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh \
    && \
    sh ./installer.sh ~/.config/nvim

RUN nvim +:UpdateRemotePlugins +qa
RUN chmod -R 777 /root

ENTRYPOINT ["nvim"]
