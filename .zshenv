typeset -U PATH path

ZSH_CACHE_DIR=$HOME/.cache/zsh

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
# browser
if [ -n "$DISPLAY" ]; then
    export BROWSER="firefox"
else
    export BROWSER=w3m
fi
# nnn file manager
export NNN_OPTS='EFHux'
export NNN_PLUG='z:autojump;S:suedit;l:-!git log;p:-!less -iR $nnn*'
export NNN_BMS='d:~/Documents;D:~/Downloads/;r:~/repos/'
export NNN_TRASH=1

# .local/bin
export PATH="$HOME/.local/bin:$PATH"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"
