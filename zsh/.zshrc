
# Initialize Zsh completion and prompt
autoload -Uz compinit promptinit
compinit
promptinit

# Starship prompt
eval "$(starship init zsh)"

# Add tools to PATH
export PATH="$PATH:/home/narayan/.spicetify"
export PATH="$HOME/.shorebird/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk/"

# Node Version Manager
source /usr/share/nvm/init-nvm.sh

# Dart CLI completion (if available)
[[ -f $HOME/.dart-cli-completion/zsh-config.zsh ]] && source $HOME/.dart-cli-completion/zsh-config.zsh

# Zinit Plugin Manager
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Zinit plugins and annexes
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions

# fzf bindings
source <(fzf --zsh)

# Custom environment
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# Aliases
alias ls="eza"
alias vim="nvim"
alias inv='nvim $(fzf -m --preview="bat --color=always {}")'

# Shell history settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
