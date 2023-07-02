# docker run -w /tmp -it --rm alpine:edge sh -uelic 'addgroup -S lunaruser && adduser -S lunaruser -G lunaruser --shell /bin/sh && apk add yarn git python3 cargo neovim ripgrep alpine-sdk bash --update && LV_BRANCH='release-1.3/neovim-0.9' su -c "bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/release-1.3/neovim-0.9/utils/installer/install.sh)" lunaruser && su -c /home/lunaruser/.local/bin/lvim lunaruser'


FROM ubuntu
LABEL author="Jonathan M. Wilbur <jonathan@wilbur.space>"
LABEL app="neovim"
ENV HOME="/root"
WORKDIR /lunar
RUN apt update && apt install -y curl git make python3 python3-pip

# Install Neovim
RUN curl -fLO https://github.com/neovim/neovim/releases/download/v0.9.1/nvim-linux64.tar.gz
RUN tar xzvf ./nvim-linux64.tar.gz
RUN install ./nvim-linux64/bin/nvim /usr/local/bin

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

# TODO: Change to non-root user here.
# Configure NPM
# See: https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
RUN mkdir -p /usr/lib/npm
ENV NPM_CONFIG_PREFIX=/usr/lib/npm

# Install dependencies
RUN npm search neovim
RUN npm install --verbose -g neovim
RUN npm install --verbose -g tree-sitter-cli
RUN pip install pynvim
RUN cargo install ripgrep
RUN cargo install fd-find

# RUN addgroup -S lunaruser
# RUN adduser -S lunaruser -G lunaruser --shell /bin/sh
ENV LV_BRANCH="release-1.3/neovim-0.9"
RUN curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh > install.sh
RUN mkdir -p ~/.local/share/fonts
RUN cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf && cd /lunar
RUN chmod +x ./install.sh
# TODO: Should I use --local?

RUN ./install.sh --yes --install-dependencies

RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
RUN curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
RUN tar xf lazygit.tar.gz lazygit
RUN install lazygit /usr/local/bin

ENTRYPOINT ["lvim"]