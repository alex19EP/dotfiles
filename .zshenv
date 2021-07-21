typeset -U PATH path
function makedir {
	if [[ ! -d $1 ]]; then
		mkdir -p $1
	fi
}

ZSH_CACHE_DIR=$HOME/.cache/zsh
makedir $ZSH_CACHE_DIR
# zinit
declare -A ZINIT
export ZINIT[HOME_DIR]=$HOME/.local/lib/zinit
makedir $ZINIT[HOME_DIR]
export ZINIT[PLUGINS_DIR]=$ZINIT[HOME_DIR]/plugins
makedir $ZINIT[PLUGINS_DIR]
export ZINIT[COMPLETIONS_DIR]=$ZINIT[HOME_DIR]/completions
makedir $ZINIT[COMPLETIONS_DIR]
export ZINIT[SNIPPETS_DIR]=$ZINIT[HOME_DIR]/snippets
makedir $ZINIT[SNIPPETS_DIR]
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
    export BROWSER=elinks
fi
# nnn file manager
export NNN_OPTS='EFHuwx'
export NNN_PLUG='S:suedit;l:-!git log;p:-!less -iR $nnn*'
# LOS building
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
# surfraw
path=("$path[@]" /usr/lib/surfraw)
export PATH
