HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=100000
  setopt appendhistory autocd beep
bindkey -e

zstyle ':completion:*' auto-description '%d'
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' format 'completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' menu select=long-list select=0
zstyle ':completion:*' prompt '%e'
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl true
zstyle ':completion:*' verbose true
zstyle :compinstall filename '/home/erik/.zshrc'
zstyle ':completion::complete:*' gain-privileges 1
setopt COMPLETE_ALIASES
autoload -Uz compinit
compinit

# key fix
bindkey "eOH" beginning-of-line
bindkey "eOF" end-of-line

# change $PATH.
export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH

# for OhMyZsh
export ZSH=/usr/share/oh-my-zsh
ZSH_CACHE_DIR=$HOME/.oh-my-zsh-cache
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

## OhMyZsh configuration
DISABLE_UNTRACKED_FILES_DIRTY=true
# pacman do this for me
DISABLE_AUTO_UPDATE="true"
# set theme
ZSH_THEME="gentoo"
# code
VSCODE=code-insiders
# disable ls color output
DISABLE_LS_COLORS="true"
# don't update terminal window-title
DISABLE_AUTO_TITLE="true"
# yep. i do typos
ENABLE_CORRECTION="true"
# set custom directory
ZSH_CUSTOM=$HOME/omz-custom
# OhMyZsh plugins
plugins=(
  adb
  archlinux
  command-not-found
  common-aliases
  compleat
  copybuffer
  copydir
  copyfile
  dircycle
  emoji
  emotty
  extract
  firewalld
  git
  git-auto-fetch
  git-escape-magic
  git-extras
  gitignore
  git-prompt
  gradle
  history
  jump
  magic-enter
  perms
  pip
  pj
  profiles
  rand-quote
  repo
  safe-paste
  sudo
  systemadmin
  systemd
  themes
  tmux
  tmux-cssh
  vscode
  zsh_reload
)

emotty_set=nature
PROJECT_PATHS=(~/building ~/repos)

# a11y fix
setopt singlelinezle

# editor
export EDITOR="$(if [[ -n $DISPLAY ]]; then echo 'code-insiders -rw'; else echo 'nano'; fi)"

# browser
if [ -n "$DISPLAY" ]; then
    export BROWSER="firefox --new-window"
else
    export BROWSER=links
fi

source $ZSH/oh-my-zsh.sh

# fix completions
compdef _yadm yadm

alias code=code-insiders

eval $(thefuck --alias)

# disable stat
zmodload -u zsh/stat

# LOS building
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

# MOTD
printf "===\n"
quote
