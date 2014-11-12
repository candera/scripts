# TODO: use something more portable than readlink
HERE_DIR=$(dirname $(readlink -e ~/.bashrc))

export PATH=$PATH:~/bin

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Enable colors for ls
export CLICOLOR=true

# gpg-agent insanity
#keychain -q
#source ~/.keychain/`hostname`-sh-gpg

# Fancy git prompt

# Colors
export ResetColor="\[\033[0m\]"            # Text reset
export Yellow="\[\033[0;33m\]"
export White='\[\033[37m\]'
export Red="\[\033[0;31m\]"
export Blue="\[\033[0;34m\]"
export BoldGreen="\[\033[1;32m\]"    # Green
export BoldBlue="\[\033[1;34m\]"     # Blue

export GIT_PROMPT_END="\n${BoldGreen}\u@$(cat ~/.machine-name)${ResetColor} $ "
source $HERE_DIR/bash-git-prompt/gitprompt.sh

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

alias ll='ls -al --color'
alias emacs='TERM=xterm-256color emacs -nw'
alias tmux='TERM=xterm-256color tmux'

if [[ -f ~/local.bashrc ]]; then
    source ~/local.bashrc
fi
