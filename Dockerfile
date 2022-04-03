# FROM python:3.10-slim-buster
FROM ubuntu:20.04

# マルチバイト文字をまともに扱うための設定
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:ja" LC_ALL="en_US.UTF-8"

# neovim は version を上げて install
RUN apt update && apt upgrade -y
RUN apt install -y software-properties-common
RUN apt-add-repository -y ppa:neovim-ppa/stable
RUN apt update
RUN apt install -y neovim
# RUN apt upgrade -y libc6 \
#     && \
#     apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 55F96FCF8231B6DD \
#     && \
#     apt install -y software-properties-common \
#     && \
#     add-apt-repository ppa:neovim-ppa/unstable \
#     && \
#     apt update \
#     && \
#     apt install -y neovim

# 最低限必要なパッケージ
# RUN apt update && \
#     apt upgrade -y && \
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

RUN pip3 install --upgrade pip pynvim isort black flake8 mypy

# install dein.vim
COPY nvim /root/.config/nvim
RUN curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh \
    && \
    sh ./installer.sh ~/.config/nvim

RUN nvim +:UpdateRemotePlugins +qa
RUN chmod -R 777 /root

ENTRYPOINT ["nvim"]


# # FROM python:3.10-slim-buster
# FROM ubuntu:18.04
# 
# # マルチバイト文字をまともに扱うための設定
# ENV LANG="en_US.UTF-8" LANGUAGE="en_US:ja" LC_ALL="en_US.UTF-8"
# 
# # 最低限必要なパッケージ
# RUN apt update && \
#     apt install -y \
#     curl \
#     gcc \
#     git \
#     libxml2-dev \
#     libxslt-dev \
#     musl-dev\
#     python3 \
#     python3-pip \
#     # ripgrep \
#     nodejs \
#     npm \
#     && \
#     npm install n -g \
#     && \
#     n stable \
#     && \
#     apt purge -y nodejs npm \
#     && \
#     rm -rf /var/cache/apt/*
# # install rg
# RUN curl https://sh.rustup.rs -sSf > rustinstall.sh \
#     && \
#     sh rustinstall.sh -y \
#     && \
#     . $HOME/.cargo/env \
#     && \
#     cargo install ripgrep
# # neovim は version を上げて install
# # RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 55F96FCF8231B6DD \
# #     && \
# #     dpkg --purge --force-depends libc6-dev \
# #     && \
# #     apt install -f -y \
# #     && \
# RUN apt install -y software-properties-common \
#     && \
#     add-apt-repository ppa:neovim-ppa/unstable \
#     && \
#     apt update \
#     && \
#     apt install -y neovim
# 
# RUN pip3 install --upgrade pip pynvim isort black flake8 mypy
# 
# # install dein.vim
# COPY nvim /root/.config/nvim
# RUN curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh \
#     && \
#     sh ./installer.sh ~/.config/nvim
# 
# RUN nvim +:UpdateRemotePlugins +qa
# RUN chmod -R 777 /root
# 
# ENTRYPOINT ["nvim"]
