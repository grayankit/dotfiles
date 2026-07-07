# Initialize Zsh completion and prompt
autoload -Uz compinit promptinit
compinit
promptinit
bindkey -v

# Starship prompt
eval "$(starship init zsh)"
eval "$(atuin init zsh)"

# Add tools to PATH
export PATH="$PATH:/home/narayan/.spicetify"
export PATH="$HOME/.shorebird/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk/"
export OPENCODE_ENABLE_EXA=1

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
alias fbl="flutter build linux --release"
alias fba="flutter build apk --release"
alias cat="bat"
alias writec="sleep 2 && xdotool type --clearmodifiers"
alias musicdl='yt-dlp -x --audio-format flac --embed-metadata --embed-thumbnail -o "~/Music/Downloads/%(artist)s - %(title)s.%(ext)s"'
speak() {
  curl -X POST http://localhost:3001/api/speak \
    -H "Content-Type: application/json" \
    -d "{\"text\":\"$*\"}"
}

# Default editor
export VISUAL='nvim'
export EDITOR='nvim'

# Shell history settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# pnpm
export PNPM_HOME="/home/narayan/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
. "/home/narayan/.deno/env"
