# =============================================================================
# POWERLEVEL10K INSTANT PROMPT
# Must stay at/near the top of the file.
# =============================================================================
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet  # keeps prompt fast, suppresses warnings
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# =============================================================================
# PATH
# typeset -U dedupes PATH automatically from here on, so it doesn't matter
# how many blocks below (NVM, Go, Android, installers, etc.) append to it —
# no entry can ever end up duplicated.
# =============================================================================
typeset -U path PATH

# Base system paths (appended to whatever PATH already exists at shell start,
# rather than replacing it, so anything set upstream by PAM/login isn't lost)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$PATH"

# User specific paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Go
export PATH="$PATH:$HOME/go/bin"   # hardcoded default GOPATH/bin — avoids forking `go env` on every shell startup

# Java & Android SDK
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:/opt/flutter/bin:$JAVA_HOME/bin:$PATH"

# Third-party tool installers
export PATH="$PATH:$HOME/.lmstudio/bin"      # LM Studio CLI (lms)
export PATH="$HOME/.local/bin:$PATH"         # Antigravity CLI installer
export PATH="$HOME/.mimocode/bin:$PATH"      # mimocode


# =============================================================================
# ZINIT SETUP
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Powerlevel10k and plugins
zinit ice depth=1; zinit light romkatv/powerlevel10k

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Snippets
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

# Completion — cached, only regenerates once per 24 hours
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


# =============================================================================
# SHELL OPTIONS
# =============================================================================
setopt interactive_comments


# =============================================================================
# HISTORY
# =============================================================================
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE

# Core settings
setopt appendhistory
setopt sharehistory          # shares history live across all open terminal windows
setopt hist_ignore_space     # skip commands prefixed with a leading space
setopt extended_history      # pins the ": <timestamp>:<elapsed>;command" format so it
                              # can never silently drift between plain/timestamped
                              # entries — that drift was what broke deduping and made
                              # commands like `top` show up twice.

# Deduplication
setopt hist_ignore_all_dups  # a new duplicate command deletes the old entry
setopt hist_save_no_dups     # never write duplicate commands to disk
setopt hist_find_no_dups     # skip duplicates when searching history


# =============================================================================
# COMPLETION STYLING
# =============================================================================
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# =============================================================================
# KEYBINDINGS
# =============================================================================
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey ' ' magic-space


# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================
export EDITOR=vim
export TERMINAL=kitty
export CHROME_EXECUTABLE=brave


# =============================================================================
# NVM — fast startup + full binary access
# Adds the default node bin to PATH immediately (no nvm.sh sourcing needed for
# that). The `nvm` command itself lazy-loads only when explicitly invoked.
# =============================================================================
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

# System-package nvm init, kept as a fallback in case the block above doesn't
# find a default alias yet (harmless no-op otherwise)
[ -s "/usr/share/nvm/init-nvm.sh" ] && source "/usr/share/nvm/init-nvm.sh"


# =============================================================================
# FZF & ZOXIDE
# =============================================================================
if command -v fzf >/dev/null 2>&1; then
  if [ -f "/usr/share/fzf/completion.zsh" ]; then
    source "/usr/share/fzf/completion.zsh"
  fi
fi

# zoxide — run once at startup, not on every prompt
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Fully remove a package + its user config/cache/autostart entry (Arch/pacman)
remove() {
  if [ -z "$1" ]; then
    echo "Usage: remove appname"
    return 1
  fi

  local APP="$1"
  sudo pacman -Rns "$APP" || { echo "🛑 Removal aborted."; return 1; }
  pkill "$APP" 2>/dev/null
  rm -rf ~/.config/"$APP" ~/.cache/"$APP" ~/.local/share/"$APP" ~/.config/autostart/org."$APP"."$APP".desktop
  echo "$APP removed with config cleaned."
}

# Nuke a package plus its pacman/paru/yay caches
nuke() {
    if [[ -z "$1" ]]; then
        echo "❌ Error: You must specify a package name."
        echo "💡 Usage: nuke <package_name>"
        return 1
    fi

    local pkg="$1"
    echo "🔥 Preparing to completely obliterate: $pkg"

    # Step 1: Remove package, unused dependencies, and global configs
    echo "📦 Running pacman removal..."
    # '|| return 1' so pressing 'n' to abort pacman stops the function instantly.
    sudo pacman -Rns "$pkg" || { echo "🛑 Uninstallation aborted. Caches were untouched."; return 1; }

    # Step 2: Clear system pacman cache for the package
    echo "🧹 Scrubbing system pacman cache..."
    # '-[0-9]*' forces matching the version number right after the dash, so
    # 'nuke gcc' doesn't accidentally delete the cache for 'gcc-libs'.
    sudo rm -f /var/cache/pacman/pkg/"$pkg"-[0-9]*

    # Step 3: Clear Paru AUR cache (if it exists)
    if [[ -d "$HOME/.cache/paru/clone/$pkg" ]]; then
        echo "🧹 Scrubbing paru cache..."
        rm -rf "$HOME/.cache/paru/clone/$pkg"
    fi

    # Step 4: Clear Yay AUR cache (if it exists)
    if [[ -d "$HOME/.cache/yay/$pkg" ]]; then
        echo "🧹 Scrubbing yay cache..."
        rm -rf "$HOME/.cache/yay/$pkg"
    fi

    echo "✅ Done. $pkg and its system/AUR caches have been wiped."
}


# =============================================================================
# PERSONAL ALIASES
# Loaded last so the functions/exports above are available to them. Guarded
# so a missing file doesn't throw an error on every shell startup.
# =============================================================================
[[ -f ~/.aliases ]] && source ~/.aliases
