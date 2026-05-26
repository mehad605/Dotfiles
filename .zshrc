# -------------------------------
# Powerlevel10k Instant Prompt
# -------------------------------
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet  # keeps prompt fast, suppresses warnings
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# -------------------------------
# Zinit setup
# -------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# -------------------------------
# Powerlevel10k and plugins
# -------------------------------
zinit ice depth=1; zinit light romkatv/powerlevel10k

# zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::docker
zinit snippet OMZP::uv
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# completion — cached, only regenerates once per 24 hours
autoload -Uz compinit
if [[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
autoload -Uz history-search-end
zinit cdreplay -q

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# -------------------------------
# Keybindings
# -------------------------------
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey ' ' magic-space

# -------------------------------
# History
# -------------------------------
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# -------------------------------
# Completion styling
# -------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# =============================================================================
# ENVIRONMENT VARIABLES & PATH
# =============================================================================
export EDITOR=vim
export TERMINAL=kitty

# Base system paths
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:~/.local/bin
# User specific paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# -------------------------------
# NVM — Fast startup + full binary access
# Adds default node bin to PATH immediately (no nvm.sh sourcing)
# nvm command itself lazy-loads only when needed
# -------------------------------
export NVM_DIR="$HOME/.nvm"

# Resolve default version (follows alias chains like lts/* → lts/iron → v20.x.x)
_nvm_resolve_default() {
  local version_file="$NVM_DIR/alias/default"
  [[ -f "$version_file" ]] || return 1

  local version
  version=$(cat "$version_file")

  # Follow alias chains (e.g. lts/* → lts/iron → v20.11.0)
  local max_depth=5
  while [[ $max_depth -gt 0 && -f "$NVM_DIR/alias/$version" ]]; do
    version=$(cat "$NVM_DIR/alias/$version")
    (( max_depth-- ))
  done

  # Strip leading 'v' if present, then find matching installed version
  version="${version#v}"
  local node_path
  node_path=$(ls -d "$NVM_DIR/versions/node/v${version}"* 2>/dev/null | sort -V | tail -1)

  [[ -n "$node_path" ]] && echo "$node_path/bin"
}

_NVM_BIN=$(_nvm_resolve_default)
if [[ -n "$_NVM_BIN" ]]; then
  export PATH="$_NVM_BIN:$PATH"
fi
unfunction _nvm_resolve_default
unset _NVM_BIN

# nvm itself lazy-loads only when you explicitly call it (e.g. nvm use, nvm install)
nvm() {
  unfunction nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Java & Android SDK Config
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export ANDROID_HOME=$HOME/Android/Sdk

# PATH Ordering
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:/opt/flutter/bin:$JAVA_HOME/bin:$PATH"

# Web Config
export CHROME_EXECUTABLE=brave

# -------------------------------
# fzf and zoxide initialization
# -------------------------------
# fzf
if command -v fzf >/dev/null 2>&1; then
  if [ -f "/usr/share/fzf/completion.zsh" ]; then
    source "/usr/share/fzf/completion.zsh"
  fi
fi

# zoxide — run once at startup, not on every prompt
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# -------------------------------
# Utility functions
# -------------------------------
remove() {
  if [ -z "$1" ]; then
    echo "Usage: remove appname"
    return 1
  fi

  APP="$1"
  sudo apt remove --purge -y "$APP"
  pkill "$APP" 2>/dev/null
  rm -rf ~/.config/"$APP" ~/.cache/"$APP" ~/.local/share/"$APP" ~/.config/autostart/org."$APP"."$APP".desktop
  echo "$APP removed with config cleaned."
}

# Load personal aliases
source ~/.aliases

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/maruf/.lmstudio/bin"
# End of LM Studio CLI section
#
# GO
export PATH=$PATH:$(go env GOPATH)/bin
#

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/share/nvm/init-nvm.sh" ] && source "/usr/share/nvm/init-nvm.sh"
setopt interactive_comments
