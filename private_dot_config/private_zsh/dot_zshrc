# Source zstyles you might use with antidote.
[[ -e ${ZDOTDIR:-~}/.zstyles ]] && source ${ZDOTDIR:-~}/.zstyles

# Clone antidote if necessary.
[[ -d ${ZDOTDIR:-~}/.antidote ]] ||
  git clone https://github.com/mattmc3/antidote ${ZDOTDIR:-~}/.antidote

# source antidote
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# aliases
[ -f "${ZDOTDIR}/aliases" ] && source "${ZDOTDIR}/aliases" ||:

HISTFILE="$XDG_STATE_HOME"/zsh/history
WORDCHARS="${WORDCHARS/\//}"

# zstyle
zstyle ':completion:*' completer _expand_alias _complete _match  _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}'
# do not complete . and .. special directories
zstyle ':completion:*' special-dirs false
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' use-compctl true
zstyle ':completion:*' verbose true
zstyle ':completion:*' list-grouped true
zstyle ':completion:*' list-suffixes true
zstyle ':completion::complete:*' gain-privileges 1
# Ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:-command-:*:*' ignored-patterns '_*'
# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'
# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
autoload -Uz run-help
autoload -Uz run-help-git run-help-ip run-help-openssl run-help-sudo run-help-svn
autoload -Uz edit-command-line

# code
VSCODE=code-insiders

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line

setopt BEEP
setopt COMPLETE_ALIASES GLOB_COMPLETE COMPLETE_IN_WORD LIST_PACKED
setopt auto_param_slash     # if completed parameter is a directory, add a trailing slash
TRAPUSR1() { rehash }

# Do not offer completion functions as corrections
CORRECT_IGNORE='_*'

# History
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY_TIME

# Input/Output
setopt CORRECT
setopt CORRECT_ALL

# Prompting
setopt PROMPT_SUBST

setopt NOMATCH

## Key bindings

# https://web.archive.org/web/20180704181216/http://zshwiki.org/home/zle/bindkeys

# Use Emacs-like keybindings
bindkey -e

# Create a zkbd compatible hash. To add other keys to this hash, see: man 5 terminfo and man 5 user_caps.
typeset -g -A key

key[Control]='\C-'
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
[[ -n "${key[Shift-Tab]}"     ]] && bindkey -- "${key[Shift-Tab]}"     reverse-menu-complete
[[ -n "${key[Control-Left]}"  ]] && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word
[[ -n "${key[Control]}" ]] && bindkey -- "${key[Control]}X${key[Control]}E" edit-command-line

# Finally, make sure the terminal is in application mode, when zle is active. Only then are the values from $terminfo valid.
# https://www.zsh.org/mla/users/2010/msg00065.html
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start () { echoti smkx }
    function zle_application_mode_stop () { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

export GIT_PROFILES_FILE="$HOME/.config/git/profiles"
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    #source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
fi
if [[ -f /usr/share/nnn/quitcd/quitcd.bash_sh_zsh ]]; then
    source /usr/share/nnn/quitcd/quitcd.bash_sh_zsh
fi
if [[ -f /usr/share/doc/mcfly/mcfly.zsh ]]; then
    source /usr/share/doc/mcfly/mcfly.zsh
fi

(( ${+commands[zoxide]} )) && emulate zsh -c "$(zoxide init --hook pwd zsh)"
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.config/p10k/p10k.zsh ]] || source ~/.config/p10k/p10k.zsh
