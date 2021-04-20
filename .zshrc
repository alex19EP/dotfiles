# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=5000
setopt appendhistory beep

zstyle ':completion::complete:*' cache-path "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompcache"
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*' auto-description '%d'
zstyle ':completion:*' completer _expand _complete _ignored _approximate _correct
zstyle ':completion:*' format 'completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' menu select=long-list select=1
zstyle ':completion:*' prompt '%e'
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl true
zstyle ':completion:*' verbose true
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' list-grouped true
zstyle ':completion:*' list-suffixes true

zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections true

# Ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:-command-:*:*' ignored-patterns '_*'

zstyle ':completion::complete:*' gain-privileges 1
setopt COMPLETE_ALIASES GLOB_COMPLETE COMPLETE_IN_WORD LIST_PACKED


autoload -Uz compinit
compinit

# Do not offer completion functions as corrections
CORRECT_IGNORE='_*'

# Expansion and Globbing
setopt EXTENDED_GLOB
setopt GLOB_DOTS

# History
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FCNTL_LOCK
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY_TIME

# Input/Output
setopt CORRECT
setopt CORRECT_ALL
setopt INTERACTIVE_COMMENTS
setopt RM_STAR_WAIT

# Job Control
setopt LONG_LIST_JOBS

# Prompting
setopt PROMPT_SUBST

# Changing Directories
setopt AUTO_CD

## Key bindings

# https://web.archive.org/web/20180704181216/http://zshwiki.org/home/zle/bindkeys

# Use Emacs-like keybindings
bindkey -e

# Create a zkbd compatible hash. To add other keys to this hash, see: man 5 terminfo and man 5 user_caps.
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"
key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"

# Setup key accordingly
[[ -n "${key[Home]}"          ]] && bindkey -- "${key[Home]}"          beginning-of-line
[[ -n "${key[End]}"           ]] && bindkey -- "${key[End]}"           end-of-line
[[ -n "${key[Insert]}"        ]] && bindkey -- "${key[Insert]}"        overwrite-mode
[[ -n "${key[Backspace]}"     ]] && bindkey -- "${key[Backspace]}"     backward-delete-char
[[ -n "${key[Delete]}"        ]] && bindkey -- "${key[Delete]}"        delete-char
[[ -n "${key[Up]}"            ]] && bindkey -- "${key[Up]}"            up-line-or-beginning-search
[[ -n "${key[Down]}"          ]] && bindkey -- "${key[Down]}"          down-line-or-beginning-search
[[ -n "${key[Left]}"          ]] && bindkey -- "${key[Left]}"          backward-char
[[ -n "${key[Right]}"         ]] && bindkey -- "${key[Right]}"         forward-char
[[ -n "${key[PageUp]}"        ]] && bindkey -- "${key[PageUp]}"        beginning-of-line-hist
[[ -n "${key[PageDown]}"      ]] && bindkey -- "${key[PageDown]}"      end-of-line-hist
[[ -n "${key[Shift-Tab]}"     ]] && bindkey -- "${key[Shift-Tab]}"     reverse-menu-complete
[[ -n "${key[Control-Left]}"  ]] && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word

# Finally, make sure the terminal is in application mode, when zle is active. Only then are the values from $terminfo valid.
# https://www.zsh.org/mla/users/2010/msg00065.html
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start () { echoti smkx }
	function zle_application_mode_stop () { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

# change $PATH.
export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH

# for OhMyZsh
export ZSH=/usr/share/oh-my-zsh
ZSH_CACHE_DIR=$HOME/.cache/zsh/zcompcache
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

## OhMyZsh configuration
DISABLE_UNTRACKED_FILES_DIRTY=true
# pacman will do this for me
DISABLE_AUTO_UPDATE="true"
# set theme
ZSH_THEME="gentoo"
# code
VSCODE=code-insiders
# help me trying to learn aliases
ZSH_ALIAS_FINDER_AUTOMATIC=true
# disable ls color output
DISABLE_LS_COLORS="true"
# don't update terminal window-title
DISABLE_AUTO_TITLE="true"
# set custom directory
ZSH_CUSTOM=$HOME/.config/oh-my-zsh
# OhMyZsh plugins
plugins=(
  adb
  alias-finder
  archlinux
  command-not-found
  common-aliases
  compleat
  copybuffer
  copydir
  copyfile
  dircycle
  extract
  firewalld
  git
  git-escape-magic
  git-extras
  gitignore
  gradle
  history
  jump
  perms
  pip
  pj
  profiles
  repo
  safe-paste
  sudo
  systemadmin
  systemd
  tmux
  tmux-cssh
  vscode
  zsh_reload
  web-search
  fzf
)

emotty_set=nature
PROJECT_PATHS=(~/building ~/repos)

ZSH_TMUX_CONFIG="$HOME/.config/tmux/tmux.conf"

# editor
export EDITOR="$(if [[ -n $DISPLAY ]]; then echo 'code-insiders -rw'; else echo 'nano'; fi)"

# browser
if [ -n "$DISPLAY" ]; then
    export BROWSER="firefox --new-window"
else
    export BROWSER=links
fi

source $ZSH/oh-my-zsh.sh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
if [ -f /usr/share/nnn/quitcd/quitcd.bash_zsh ]; then
    source /usr/share/nnn/quitcd/quitcd.bash_zsh
    export NNN_OPTS="EFrwx"
fi

alias code=code-insiders

# disable stat
zmodload -u zsh/stat

# LOS building
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.config/p10k/p10k.zsh ]] || source ~/.config/p10k/p10k.zsh
