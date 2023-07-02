FROM ubuntu
LABEL author="Jonathan M. Wilbur <jonathan@wilbur.space>"
LABEL app="neovim"
RUN apt update && apt install -y neovim
CMD ["nvim"]
