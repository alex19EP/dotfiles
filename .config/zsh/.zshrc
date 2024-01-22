### Added by Zinit's installer
if [[ ! -f $ZINIT[HOME_DIR]/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command chmod g-rwX "$ZINIT[HOME_DIR]"
    command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT[HOME_DIR]/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

module_path+=( "$HOME/.local/lib/zinit/module/Src" )
source "$ZINIT[HOME_DIR]/bin/zinit.zsh"
autoload -Uz _zinit
if [[ -f "$HOME/.local/lib/zinit/module/Src/zdharma_continuum/zinit.so" ]]; then
    zmodload zdharma_continuum/zinit
fi
(( ${+_comps} )) && _comps[zinit]=_zinit

### End of Zinit's installer chunk

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
(( ${+commands[zoxide]} )) && emulate zsh -c "$(zoxide init zsh)"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"

function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=(
        ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"}
    )
    if (( ${#entries[@]} ))
    then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}"
        do
            # (repo package version file)
            local fields=(
                ${(0)entry}
            )
            if [[ "$pkg" != "${fields[2]}" ]]
            then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
}

HISTFILE="$XDG_STATE_HOME"/zsh/history
HISTSIZE=100000
SAVEHIST=500000
WORDCHARS="${WORDCHARS/\//}"

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
autoload -Uz run-help
(( ${+aliases[run-help]} )) && unalias run-help
alias help=run-help
autoload -Uz run-help-git run-help-ip run-help-openssl run-help-sudo run-help-svn
autoload -Uz edit-command-line

# code
VSCODE=code-insiders

zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*' auto-description '%d'
zstyle ':completion:*' completer _expand_alias _complete _correct _approximate
zstyle ':completion:*' format 'completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}'
# do not complete . and .. special directories
zstyle ':completion:*' special-dirs false
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' menu select=long-list select=0
zstyle ':completion:*' prompt '%e'
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl true
zstyle ':completion:*' verbose true
zstyle ':completion:*' list-grouped true
zstyle ':completion:*' list-suffixes true
# Ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:-command-:*:*' ignored-patterns '_*'
zstyle ':completion::complete:*' gain-privileges 1
# Don't complete uninteresting users...
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
  dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
  hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
  mailman mailnull mldonkey mysql nagios \
  named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
  operator pcap postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'
# ... unless we really want to.
zstyle '*' single-ignored show
# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'
# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single
# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line

setopt APPENDHISTORY SHARE_HISTORY BEEP
setopt COMPLETE_ALIASES GLOB_COMPLETE COMPLETE_IN_WORD LIST_PACKED
setopt auto_param_slash     # if completed parameter is a directory, add a trailing slash
setopt always_to_end        # move cursor to the end of a completed word
TRAPUSR1() { rehash }

# Do not offer completion functions as corrections
CORRECT_IGNORE='_*'

# Expansion and Globbing
setopt EXTENDED_GLOB
setopt GLOB_DOTS

# History
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FCNTL_LOCK
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY_TIME
setopt SHARE_HISTORY

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
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_TO_HOME

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

alias code=code-insiders

# plugins
zinit wait lucid for \
           OMZP::git \
           OMZP::gitignore \
           OMZP::gradle \
           OMZP::history \
           OMZP::pip \
           OMZP::repo \
           OMZP::safe-paste \
           OMZP::sudo \
           OMZP::systemadmin \
           mellbourn/zabb \
      as"completion" \
           OMZP::adb/_adb
if (( $+commands[code] || $+commands[code-insiders] )); then
    zinit snippet OMZP::vscode
fi
zinit ice depth=1; zinit light romkatv/powerlevel10k

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

autoload -Uz compinit
compinit -d $ZINIT[ZCOMPDUMP_PATH]

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.config/p10k/p10k.zsh ]] || source ~/.config/p10k/p10k.zsh

# aliases
[ -f "${ZDOTDIR}/aliases" ] && source "${ZDOTDIR}/aliases" ||:
