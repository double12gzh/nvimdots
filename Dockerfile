# 第一个阶段：基础依赖镜像
ARG NVIM_VERSION=v0.9.5
ARG NVIM_CONFIG=https://github.com/double12gzh/nvimdots.git
ARG DOTFILES=https://github.com/double12gzh/dotfiles.git

FROM ubuntu:22.04 AS base

# 设置环境变量以避免交互安装
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 更新系统并安装依赖项
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    zsh \
    locales \
    build-essential \
    software-properties-common && \
    echo "console-setup console-setup/charmap47 select UTF-8" | debconf-set-selections && \
    apt-get install -y \
    tzdata \
    console-setup \
    nala && \
    dpkg-reconfigure -f noninteractive tzdata && \
    chsh -s $(which zsh) && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen


# 第二个阶段：基础依赖镜像
FROM ubuntu:22.04 AS dotfiles-sys

ARG DOTFILES
ARG NVIM_CONFIG
ARG NVIM_VERSION

COPY --from=base / /

# 设置工作目录
WORKDIR /root

ARG DOTFILE_INSTALL=/root/dotfiles/zzz_install_scripts

# 设置环境变量以避免交互安装
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN git clone "$DOTFILES" /root/dotfiles && mkdir /root/tools /root/packages && \
    sed -i "s@nightly@$NVIM_VERSION@g" "$DOTFILE_INSTALL"/apps/nvim.sh && \
    sed -i "s@1.19.3@1.22.8@g" "$DOTFILE_INSTALL"/langs/golang.sh && \
    sed -i "s@luajit.org/download/LuaJIT-2.0.5.tar.gz@github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.0.5.tar.gz@g" "$DOTFILE_INSTALL"/langs/lua.sh && \
    sed -i "s@sudo@@g" "$DOTFILE_INSTALL"/sys-apps/apt_install.sh && \
    sed -i "/conda.sh/d" "$DOTFILE_INSTALL"/install_lang.sh && \
    sed -i "/apt install -y ascii-image-converter/d" "$DOTFILE_INSTALL"/sys-apps/apt_install.sh && \
    sed -i "s/nala install pkg-config/yes ''|nala install pkg-config/g" $DOTFILE_INSTALL/sys-apps/apt_install.sh && \
    sed -i "/java.sh/d" "$DOTFILE_INSTALL"/install_lang.sh && \
    sed -i "/conda.sh/d" "$DOTFILE_INSTALL"/install_lang.sh && \
    sed -i "/php.sh/d" "$DOTFILE_INSTALL"/install_lang.sh && \
    sed -i "/ruby.sh/d" "$DOTFILE_INSTALL"/install_lang.sh && \
    sed -i "/wait_for_user/d" "$DOTFILE_INSTALL"/config.sh && \
    sed -i "s@make all test@make all@g" "$DOTFILE_INSTALL"/langs/lua.sh

RUN cd "$DOTFILE_INSTALL"/sys-apps && bash apt_install.sh


# 第三个阶段：基础依赖镜像
FROM ubuntu:22.04 AS dotfiles-lang

COPY --from=dotfiles-sys / /

ARG DOTFILE_INSTALL=/root/dotfiles/zzz_install_scripts

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN cd "$DOTFILE_INSTALL" && bash install_lang.sh


# 第四个阶段：基础依赖镜像
FROM ubuntu:22.04 AS dotfiles-app

COPY --from=dotfiles-lang / /

ENV PATH=/root/go/bin:/root/tools/golang/bin:/root/.cargo/bin:/root/tools/perl/bin:$PATH
ENV LUA_LIBRARY="/root/tools/luajit/src/libluajit.so"
ENV PERL_CPANM_HOME="/root/tools/cpanm"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ARG DOTFILE_INSTALL=/root/dotfiles/zzz_install_scripts

RUN cd "$DOTFILE_INSTALL" && bash install_app.sh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# 第五个阶段：基础依赖镜像
FROM ubuntu:22.04 AS nvim

ARG NVIM_CONFIG
ARG NVIM_VERSION

ENV TERM=xterm-256color

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV PATH="/root/.local/share/zinit/plugins/eth-p---bat-extras/src"
ENV PATH="/root/.local/share/zinit/plugins/junegunn---fzf-tmux/bin:$PATH"
ENV PATH="/root/.local/share/zinit/plugins/sharkdp---bat/usr/bin:$PATH"
ENV PATH="/root/.local/share/zinit/plugins/junegunn---fzf:$PATH"
ENV PATH="/root/.local/share/zinit/polaris/bin:$PATH"
ENV PATH="/root/.local/bin:$PATH"
ENV PATH="/root/tools/anaconda/bin:$PATH"
ENV PATH="/root/tools/qfc/bin:$PATH"
ENV PATH="/root/tools/ugrep/bin:$PATH"
ENV PATH="/root/tools/treesitter:$PATH"
ENV PATH="/root/tools/tmux:$PATH"
ENV PATH="/root/tools/stow/bin:$PATH"
ENV PATH="/root/tools/nvim/bin:$PATH"
ENV PATH="/root/tools/lnav:$PATH"
ENV PATH="/root/tools/jq:$PATH"
ENV PATH="/root/tools/fzy:$PATH"
ENV PATH="/root/tools/fzf/bin:$PATH"
ENV PATH="/root/tools/cpufetch:$PATH"
ENV PATH="/root/tools/btop/bin:$PATH"
ENV PATH="/root/tools/ruby/bin:$PATH"
ENV PATH="/root/tools/php/bin:$PATH"
ENV PATH="/root/tools/perl/bin:$PATH"
ENV PATH="/root/tools/nodejs/bin:$PATH"
ENV PATH="/root/tools/luarocks:$PATH"
ENV PATH="/root/tools/luajit/src:$PATH"
ENV PATH="/root/tools/lua/src:$PATH"
ENV PATH="/root/tools/julia/bin:$PATH"
ENV PATH="/root/tools/java/bin:$PATH"
ENV PATH="/root/tools/golang/bin:$PATH"
ENV PATH="/root/tools/stow/bin:$PATH"
ENV PATH="/root/tools/nvim/bin:$PATH"
ENV PATH="/root/tools/lnav:$PATH"
ENV PATH="/root/tools/jq:$PATH"
ENV PATH="/root/.cargo/bin:$PATH"
ENV PATH="/root/go/bin:$PATH"
ENV PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

COPY --from=dotfiles-app / /

RUN git clone https://github.com/double12gzh/nvimdots.git ~/.config/nvim && \
    sed -i 's/settings\["use_ssh"\] = true/settings\["use_ssh"\] = false/' ~/.config/nvim/lua/core/settings.lua && \
    rm -rf ~/.zshenv && cd /root/dotfiles && stow batcat cargo dlv fdfind git gotests lazygit lf local luarocks pip ssh starship tmux tmuxp zsh -R && \
    zsh -c 'echo "success"'

# 安装 Neovim 插件
RUN nvim --headless +Lazy +MasonInstallAll +TSUpdate +qall


# 最终阶段：轻量级运行镜像
FROM ubuntu:22.04 AS final

# 设置环境变量以避免交互安装
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 从 nvim 镜像复制安装好的内容到 final 镜像
COPY --from=nvim / /

WORKDIR /home

RUN rm -rf /root/packages

# 入口点设置为 nvim
CMD ["zsh", "-c", "source ~/.zshrc && exec zsh"]
