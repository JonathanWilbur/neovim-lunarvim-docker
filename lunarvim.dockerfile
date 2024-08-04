# docker run -w /tmp -it --rm alpine:edge sh -uelic 'addgroup -S lunaruser && adduser -S lunaruser -G lunaruser --shell /bin/sh && apk add yarn git python3 cargo neovim ripgrep alpine-sdk bash --update && LV_BRANCH='release-1.3/neovim-0.9' su -c "bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/release-1.3/neovim-0.9/utils/installer/install.sh)" lunaruser && su -c /home/lunaruser/.local/bin/lvim lunaruser'
# docker run -w /tmp -it --rm alpine:edge sh -uelic 'addgroup -S lunaruser && adduser -S lunaruser -G lunaruser --shell /bin/sh && apk add yarn git python3 cargo neovim ripgrep alpine-sdk bash curl --update && LV_BRANCH='release-1.4/neovim-0.9' su -c "bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/release-1.4/neovim-0.9/utils/installer/install.sh) --no-install-dependencies" lunaruser && su -c /home/lunaruser/.local/bin/lvim lunaruser'
# LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh)

FROM ubuntu
LABEL author="Jonathan M. Wilbur <jonathan@wilbur.space>"
LABEL app="neovim"
ENV HOME="/root"

RUN apt update && apt install -y yarn git python3 bash curl pip adduser python3-pynvim
RUN addgroup --system lunaruser
RUN adduser --system lunaruser --shell /bin/bash --home /home/lunaruser
WORKDIR /lunar
RUN LV_BRANCH='release-1.4/neovim-0.9'

RUN mkdir -p ~/.local/share/fonts
RUN cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf && cd /lunar

# Install Neovim
# RUN curl -fLO https://github.com/neovim/neovim/releases/download/v0.9.1/nvim-linux64.tar.gz
# RUN tar xzvf ./nvim-linux64.tar.gz
# RUN install ./nvim-linux64/bin/nvim /usr/local/bin

RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
RUN rm -rf /opt/nvim
RUN tar -C /opt -xzf nvim-linux64.tar.gz
ENV PATH="$PATH:/opt/nvim-linux64/bin"

# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_20.x > setup_20.x.sh
RUN chmod +x ./setup_20.x.sh
RUN ./setup_20.x.sh
RUN apt install -y nodejs

# Install cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > ./rustup.sh
RUN chmod +x ./rustup.sh
RUN ./rustup.sh -y
ENV PATH="$HOME/.cargo/bin:$PATH"

# USER lunaruser
# Configure NPM
# See: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
RUN mkdir -p /usr/lib/npm
ENV NPM_CONFIG_PREFIX=/usr/lib/npm

# Install dependencies
RUN npm search neovim
RUN npm install --verbose -g neovim
RUN npm install --verbose -g tree-sitter-cli
# RUN pip install python3-pynvim (Installed using apt.)
RUN cargo install ripgrep
RUN cargo install fd-find

# RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
# https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.43.1_Linux_x86_64.tar.gz
ENV LAZYGIT_VERSION="0.43.1"
RUN curl -L "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -o lazygit.tar.gz
RUN tar xvzf lazygit.tar.gz
RUN install lazygit /usr/local/bin

RUN mkdir -p /home/lunaruser
RUN chown -R lunaruser:lunaruser /home/lunaruser
USER lunaruser
ENV HOME="/home/lunaruser"
WORKDIR /home/lunaruser

RUN mkdir -p "$HOME/.local/share/lunarvim/lvim"
RUN mkdir -p "$HOME/.config/lvim"
RUN mkdir -p "$HOME/.cache/lvim"

RUN curl -L https://github.com/LunarVim/LunarVim/archive/refs/tags/1.4.0.tar.gz -o lunarvim.tar.gz
# TODO: Verify hash
RUN tar -C "$HOME/.local/share/lunarvim/lvim" --strip-components 1 -xvzf lunarvim.tar.gz
RUN mkdir -p "$HOME/.local/bin"
RUN cp "$HOME/.local/share/lunarvim/lvim/utils/bin/lvim.template" "$HOME/.local/bin/lvim"

ENV LUNARVIM_RUNTIME_DIR="$HOME/.local/share/lunarvim"
ENV LUNARVIM_CONFIG_DIR="$HOME/.config/lvim"
ENV LUNARVIM_CACHE_DIR="$HOME/.cache/lvim"
ENV LUNARVIM_BASE_DIR="$LUNARVIM_RUNTIME_DIR/lvim"

RUN sed -e s"#NVIM_APPNAME_VAR#\"lvim\"#"g \
    -e s"#RUNTIME_DIR_VAR#\"${LUNARVIM_RUNTIME_DIR}\"#"g \
    -e s"#CONFIG_DIR_VAR#\"${LUNARVIM_CONFIG_DIR}\"#"g \
    -e s"#CACHE_DIR_VAR#\"${LUNARVIM_CACHE_DIR}\"#"g \
    -e s"#BASE_DIR_VAR#\"${LUNARVIM_BASE_DIR}\"#"g \
    "$HOME/.local/share/lunarvim/lvim/utils/bin/lvim.template" \
    | tee "$HOME/.local/bin/lvim" >/dev/null

RUN chmod u+x "$HOME/.local/bin/lvim"

RUN cp "$HOME/.local/share/lunarvim/lvim/utils/installer/config.example.lua" "$HOME/.config/lvim/config.lua"

# I don't think this is necessary.
# RUN "$INSTALL_PREFIX/bin/$NVIM_APPNAME" --headless -c 'quitall'

# I don't think this is necessary either.
# RUN /utils/ci/verify_plugins.sh
# BASEDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# BASEDIR="$(dirname -- "$(dirname -- "$BASEDIR")")"
# LUNARVIM_BASE_DIR="${LUNARVIM_BASE_DIR:-"$BASEDIR"}"
# lvim --headless -c "luafile ${LUNARVIM_BASE_DIR}/utils/ci/verify_plugins.lua"
# (https://github.com/LunarVim/LunarVim/blob/master/utils/ci/verify_plugins.lua)

ENTRYPOINT ["/home/lunaruser/.local/bin/lvim"]
