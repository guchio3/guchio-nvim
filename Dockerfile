FROM ubuntu:20.04

# マルチバイト文字をまともに扱うための設定
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:ja" LC_ALL="en_US.UTF-8"

# neovim は version を上げて install
RUN apt update && apt upgrade -y && \
    apt install -y software-properties-common && \
    apt-add-repository -y ppa:neovim-ppa/stable && \
    apt update && \
    apt install -y neovim

# update repo
RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt update

# 最低限必要なパッケージ
RUN apt install -y \
    curl \
    gcc \
    git \
    wget \
    libxml2-dev \
    libxslt-dev \
    musl-dev\
    python3-dev \
    python3-pip \
    ripgrep \
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

# install dein.vim
COPY nvim /root/.config/nvim

# install plugins
RUN nvim +:UpdateRemotePlugins +qa

# install coc extensions
RUN nvim +'CocInstall -sync coc-json coc-sql coc-docker coc-pyright coc-go coc-git coc-json coc-yaml coc-snippets | qa'

# python env
RUN pip3 install --upgrade setuptools pip msgpack pynvim isort black flake8 mypy

# go env
RUN go install golang.org/x/tools/gopls@latest
ENV PATH=$PATH:/root/go/bin

# docker env
RUN npm install -g dockerfile-language-server-nodejs

# coc-snippet setting
# COPY nvim/coc/ultisnips /root/.config/coc/ultisnips

# chmod
RUN chmod -R 777 /root

ENTRYPOINT ["nvim"]
