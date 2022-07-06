typeset -U PATH path

# XDG
XDG_DATA_HOME=$HOME/.local/share
XDG_CONFIG_HOME=$HOME/.config
XDG_STATE_HOME=$HOME/.local/state
XDG_CACHE_HOME=$HOME/.cache
ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority
_JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
PARALLEL_HOME="$XDG_CONFIG_HOME"/parallel 
GRADLE_USER_HOME="$XDG_DATA_HOME"/gradle
RANDFILE="$XDG_CACHE_HOME"/rnd
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export SQLITE_HISTORY=$XDG_DATA_HOME/sqlite_history
ZDOTDIR=$HOME/.config/zsh
ZSH_CACHE_DIR=$XDG_CACHE_HOME/zsh
export GNUPGHOME=$XDG_DATA_HOME/gnupg

# zinit
declare -A ZINIT
export ZINIT[HOME_DIR]=$HOME/.local/lib/zinit
export ZINIT[PLUGINS_DIR]=$ZINIT[HOME_DIR]/plugins
export ZINIT[COMPLETIONS_DIR]=$ZINIT[HOME_DIR]/completions
export ZINIT[SNIPPETS_DIR]=$ZINIT[HOME_DIR]/snippets
export ZINIT[ZCOMPDUMP_PATH]="${ZSH_CACHE_DIR}/zcompdump-$ZSH_VERSION"
export ZPFX=$ZINIT[HOME_DIR]/polaris

export AUR_PAGER=nnn
# editor
export EDITOR=nano
export VISUAL="$(if [[ -n $DISPLAY || $TERM_PROGRAM = vscode ]]; then echo 'code-insiders -rw'; else echo 'nano'; fi)"
export PAGER='less'
export LESS='-giMRS'

# browser
if [ -n "$DISPLAY" ]; then
    export BROWSER="firefox"
else
    export BROWSER=w3m
fi
# nnn file manager
export NNN_OPTS='EFHux'
export NNN_PLUG='f:fixname;m:mtpmount;g:gitroot;z:autojump;S:suedit;l:-!git log;p:-!less -+F $nnn*'
export NNN_BMS='d:~/Downloads/;r:~/repos/;m:/run/user/1000/gvfs/;s:~/Sync/'
if (( $+commands[trash-put] )); then
    export NNN_TRASH=1
fi

# .local/bin
export PATH="$HOME/.local/bin:$PATH"

# cargo
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export PATH="$CARGO_HOME/bin:$PATH"
