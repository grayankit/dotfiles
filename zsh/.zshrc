autoload -Uz compinit promptinit
compinit
promptinit

eval "$(starship init zsh)"

export PATH=$PATH:/home/narayan/.spicetify
source /usr/share/nvm/init-nvm.sh

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/narayan/.dart-cli-completion/zsh-config.zsh ]] && . /home/narayan/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

export PATH="/home/narayan/.shorebird/bin:$PATH"
export PATH="/home/narayan/.bun/bin:$PATH"
export PATH="/home/narayan/.cargo/bin/:$PATH"
export ANDROID_HOME="/home/narayan/Android/Sdk/"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk
zinit light zsh-users/zsh-syntax-highlighting
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)



. "$HOME/.local/bin/env"
# Aliases

alias ls="eza"
alias vim="nvim"
#Histfile
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
# Share history in every terminal session
setopt SHARE_HISTORY
