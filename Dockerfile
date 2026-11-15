#####################################
# 第一个阶段：基础依赖镜像            #
#####################################
ARG NVIM_VERSION=v0.12.6
ARG NVIM_BRANCH=0.12
ARG TS_VERSION=v0.27.2
ARG NVIM_CONFIG=https://github.com/double12gzh/nvimdots.git
ARG DOTFILES=https://github.com/double12gzh/dotfiles.git

FROM ubuntu:24.04 AS base

# 设置环境变量以避免交互安装
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 更新系统并安装依赖项（含 fd-find / ripgrep 兜底，确保无头编译与检索工具链齐备）
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    zsh \
    locales \
    build-essential \
    software-properties-common \
    fd-find \
    ripgrep && \
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd && \
    echo "console-setup console-setup/charmap47 select UTF-8" | debconf-set-selections && \
    apt-get install -y \
    tzdata \
    console-setup \
    nala && \
    dpkg-reconfigure -f noninteractive tzdata && \
    chsh -s "$(command -v zsh)" && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen


#####################################
# 第二个阶段：系统依赖                #
#####################################
FROM ubuntu:24.04 AS dotfiles-sys

ARG DOTFILES
ARG NVIM_CONFIG
ARG NVIM_VERSION
ARG TS_VERSION

COPY --from=base / /

# 设置工作目录
WORKDIR /root

ARG DOTFILE_INSTALL=/root/dotfiles/zzz_install_scripts

# 设置环境变量以避免交互安装
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN git clone "$DOTFILES" /root/dotfiles && mkdir -p /root/tools /root/packages && \
    sed -i "s@releases/latest/download@releases/download/$NVIM_VERSION@g; s@nightly@$NVIM_VERSION@g" "$DOTFILE_INSTALL"/apps/nvim.sh && \
    sed -i "s@TS_VERSION=\"[^\"]*\"@TS_VERSION=\"$TS_VERSION\"@g" "$DOTFILE_INSTALL"/apps/treesitter.sh && \
    sed -i 's/\<sudo\>[[:space:]]*//g' "$DOTFILE_INSTALL"/sys-apps/apt_install.sh && \
    bash -n "$DOTFILE_INSTALL"/apps/nvim.sh "$DOTFILE_INSTALL"/apps/treesitter.sh "$DOTFILE_INSTALL"/sys-apps/apt_install.sh "$DOTFILE_INSTALL"/config.sh

RUN cd "$DOTFILE_INSTALL"/sys-apps && bash apt_install.sh


#####################################
# 第三个阶段：编程语言                #
#####################################
FROM ubuntu:24.04 AS dotfiles-lang

COPY --from=dotfiles-sys / /

ARG DOTFILE_INSTALL=/root/dotfiles/zzz_install_scripts

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN cd "$DOTFILE_INSTALL" && bash install_lang.sh golang julia lua nodejs perl rust


#####################################
# 第四个阶段：常用软件                #
#####################################
FROM ubuntu:24.04 AS dotfiles-app

COPY --from=dotfiles-lang / /

ENV PATH=/root/.local/bin:/root/go/bin:/root/tools/golang/bin:/root/.cargo/bin:/root/tools/perl/bin:/root/tools/lua/src:/root/tools/luajit/src:/root/tools/luarocks/bin:$PATH
ENV LUA_LIBRARY="/root/tools/luajit/src/libluajit.so"
ENV PERL_CPANM_HOME="/root/tools/cpanm"
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ARG DOTFILE_INSTALL=/root/dotfiles/zzz_install_scripts

RUN cd "$DOTFILE_INSTALL" && bash install_app.sh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#####################################
# 第五个阶段：nvim                   #
#####################################
FROM ubuntu:24.04 AS nvim

ARG NVIM_CONFIG
ARG NVIM_BRANCH
ARG NVIM_VERSION

ENV TERM=xterm-256color
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV PATH="/root/go/bin:/root/.cargo/bin:/root/tools/golang/bin:/root/tools/julia/bin:/root/tools/lua/src:/root/tools/luajit/src:/root/tools/luarocks/bin:/root/tools/luarocks:/root/tools/nodejs/bin:/root/tools/perl/bin:/root/tools/nvim/bin:/root/tools/treesitter:/root/tools/tmux/bin:/root/tools/tmux:/root/tools/stow/bin:/root/tools/lnav:/root/tools/jq:/root/tools/fzy:/root/tools/fzf/bin:/root/tools/cpufetch:/root/tools/btop/bin:/root/tools/ugrep/bin:/root/tools/qfc/bin:/root/.local/bin:/root/.local/share/zinit/polaris/bin:/root/.local/share/zinit/plugins/junegunn---fzf:/root/.local/share/zinit/plugins/sharkdp---bat/usr/bin:/root/.local/share/zinit/plugins/junegunn---fzf-tmux/bin:/root/.local/share/zinit/plugins/eth-p---bat-extras/src:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

COPY --from=dotfiles-app / /
COPY . /tmp/nvimdots-src

RUN rm -rf ~/.zshenv && \
    if [ -f /root/dotfiles/.chezmoiroot ]; then \
        chezmoi init --apply --promptDefaults --source /root/dotfiles; \
    else \
        cd /root/dotfiles && stow batcat cargo dlv fdfind git gotests lazygit lf local luarocks pip ssh starship tmux tmuxp zsh -R; \
    fi && \
    rm -rf ~/.config/nvim && \
    if git ls-remote --exit-code --heads "$NVIM_CONFIG" "$NVIM_BRANCH" >/dev/null 2>&1; then \
        git clone -b "$NVIM_BRANCH" "$NVIM_CONFIG" ~/.config/nvim; \
    elif [ -f /tmp/nvimdots-src/init.lua ]; then \
        cp -a /tmp/nvimdots-src ~/.config/nvim; \
    else \
        echo "ERROR: branch '$NVIM_BRANCH' not found in '$NVIM_CONFIG' and no local build context available" >&2; \
        exit 1; \
    fi && \
    rm -rf /tmp/nvimdots-src && \
    sed -i 's/settings\["use_ssh"\] = true/settings\["use_ssh"\] = false/' ~/.config/nvim/lua/user/settings.lua && \
    (command -v fd >/dev/null 2>&1 || (command -v fdfind >/dev/null 2>&1 && ln -sf "$(command -v fdfind)" /usr/local/bin/fd)) && \
    nvim --version && tree-sitter --version && fd --version && \
    zsh -c 'echo "success"'

# 安装 Neovim 插件、Mason 工具链（含 pylsp 子插件）与 Treesitter 语法解析器
RUN nvim --headless \
    --cmd "lua package.loaded['editor.treesitter'] = function() end" \
    "+Lazy! sync" \
    +MasonInstallAll \
    +"lua require('nvim-treesitter').setup({}); assert(require('nvim-treesitter').install(require('core.settings').treesitter_deps):wait(300000), 'nvim-treesitter parser installation failed')" \
    +qall


#####################################
# 最终阶段：轻量级运行镜像            #
#####################################
FROM ubuntu:24.04 AS final

# 设置环境变量以避免交互安装
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV PATH="/root/go/bin:/root/.cargo/bin:/root/tools/golang/bin:/root/tools/julia/bin:/root/tools/lua/src:/root/tools/luajit/src:/root/tools/luarocks/bin:/root/tools/luarocks:/root/tools/nodejs/bin:/root/tools/perl/bin:/root/tools/nvim/bin:/root/tools/treesitter:/root/tools/tmux/bin:/root/tools/tmux:/root/tools/stow/bin:/root/tools/lnav:/root/tools/jq:/root/tools/fzy:/root/tools/fzf/bin:/root/tools/cpufetch:/root/tools/btop/bin:/root/tools/ugrep/bin:/root/tools/qfc/bin:/root/.local/bin:/root/.local/share/zinit/polaris/bin:/root/.local/share/zinit/plugins/junegunn---fzf:/root/.local/share/zinit/plugins/sharkdp---bat/usr/bin:/root/.local/share/zinit/plugins/junegunn---fzf-tmux/bin:/root/.local/share/zinit/plugins/eth-p---bat-extras/src:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 从 nvim 镜像复制安装好的内容到 final 镜像
COPY --from=nvim / /

WORKDIR /home

RUN rm -rf /root/packages

# 入口点设置为 zsh
CMD ["zsh", "-c", "source ~/.zshrc && exec zsh"]
