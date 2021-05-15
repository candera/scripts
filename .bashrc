# -*- sh-basic-offset: 4 -*-

if [[ `uname` == "Darwin" ]]; then
    # greadlink requires coreutils; brew install coreutils to get it
    READLINK_CMD=greadlink
else
    READLINK_CMD=readlink
fi
PATH=${PATH}:/usr/local/sbin:/usr/local/bin
HERE_DIR=$(dirname $($READLINK_CMD -e ~/.bashrc))

export PATH=~/bin:$PATH

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

GPG_TTY=$(tty)
export GPG_TTY

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

# I switched to use the brew version of bash-git-prompt. This next
# line was how I used to do it.

# source $HERE_DIR/bash-git-prompt/gitprompt.sh

# Setup for brew version of bash-git-prompt
if [ -f "/usr/local/opt/bash-git-prompt/share/gitprompt.sh" ]; then
    __GIT_PROMPT_DIR="/usr/local/opt/bash-git-prompt/share"
    source "/usr/local/opt/bash-git-prompt/share/gitprompt.sh"
fi

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

if [[ `uname` = "Darwin" ]]; then
    alias ll='ls -alG'
else
    alias ll='ls -al --color'
fi
alias emacs='TERM=xterm-256color emacs -nw'
alias Emacs='open -a /Applications/Emacs.app'
alias tmux='TERM=xterm-256color tmux'

if [[ -f ~/local.bashrc ]]; then
    source ~/local.bashrc
fi

# Settings for boot
export BOOT_JVM_OPTIONS="-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Xmx2g -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -Xverify:none -XX:-OmitStackTraceInFastThrow"

# Enable AWS CLI completion
complete -C `which aws_completer` aws

# I've been using MySQL 5.7 for stuff, and brew doesn't automatically
# symlink it into /usr/local/bin because there's a newer version

export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"

# Set background color in iTerm

background () {
    local COLOR=$1
    local R=$(($RANDOM / 700))
    local G=$(($RANDOM / 700))
    local B=$(($RANDOM / 700))
    if [[ -z "$COLOR" ]]; then
        local LINE=$(cat ~/projects/scripts/colornames.csv | tail -n +2 | sort -R | head -n 1)
    elif [[ "$COLOR" =~ (0x)?[a-fA-F0-9]{6} ]]
    then
        local HEX=$(echo $COLOR | sed s/0x//)
        local LINE="$COLOR,#$HEX"
        local NODIM=y
    else
        local LINE=$(cat ~/projects/scripts/colornames.csv | tail -n +2 | grep -i -e "^$COLOR,")
    fi
    local NAME=$(echo "$LINE" | sed 's/,.*//')
    local VAL=$(echo "$LINE" | sed 's/\(.*,#\)\(......\)/\2/' | sed "s/$(printf '\r')//")
    local RED=$(echo $VAL | sed 's/\(..\)..../\1/')
    local GRN=$(echo $VAL | sed 's/..\(..\)../\1/')
    local BLU=$(echo $VAL | sed 's/....\(..\)/\1/')

    if [[ $NODIM == "y" ]]
    then
        local DIV=1
    else
        local DIV=3
    fi
    local R=$(printf "%02x" $((0x${RED} / $DIV)))
    local G=$(printf "%02x" $((0x${GRN} / $DIV)))
    local B=$(printf "%02x" $((0x${BLU} / $DIV)))

    COLOR="${R}${G}${B}"
    # Reference https://www.iterm2.com/documentation-escape-codes.html
    echo "Setting background to $NAME : 0x${COLOR}"
    echo -e "\033]Ph${COLOR}\033\\"
}

# Setup tab and window title functions for iterm2
# iterm behaviour: until window name is explicitly set, it'll always track tab title.
# So, to have different window and tab titles, iterm_window() must be called
# first. iterm_both() resets this behaviour and has window track tab title again).
# Source: http://superuser.com/a/344397
set_iterm_name() {
  mode=$1; shift
  echo -ne "\033]$mode;$@\007"
}
iterm_both () { set_iterm_name 0 $@; }
iterm_tab () { set_iterm_name 1 $@; }
iterm_window () { set_iterm_name 2 $@; }

function prompt_callback () {
    if [[ -n "${ADZERK_ENV}" ]]; then
        if [[ $ADZERK_MSQL_HOSTNAME =~ \.prod.opzerk.com ]]
        then
            local COLOR=${DimRedBg}
        else
            local COLOR=${DimBlueBg}
        fi
        echo " [${COLOR}(${ADZERK_MSQL_USER}@${ADZERK_MSQL_HOSTNAME})${ResetColor} ${DimBlueBg}$(echo ${ZERKENV_MODULES})${ResetColor}]"
    fi
}

# If I want paging in the output, I'll do it myself
export AWS_PAGER=""

# This prevents Adzerk's Docker setup from picking up on settings like the .bashrc from the host.
export DOCKER_USER_MODE=no

export ZERKENV_BUCKET=zerkenv
export ZERKENV_REGION=us-east-1

export PATH=$PATH:~/adzerk/zerkenv

function zerk() {
    # eval $(gpg -d --quiet ~/.zerkenv/@aws-creds.sh.asc)

    if ! ssh-add -l | grep '\.ssh/adzerk\.pem' > /dev/null
    then
        ssh-add ~/.ssh/adzerk.pem
    fi
    export ADZERK_ENV=" "
    export PATH=$PATH:~/adzerk/cli-tools/micha:~/adzerk/cli-tools/scripts:~/adzerk/teammgmt/bin:~/adzerk/teammgmt/infrastructure/bin:~/adzerk/

    export AWS_ACCESS_KEY_ID=$(gpg -d --quiet ~/.adzerk/secrets/candera/AWS_ACCESS_KEY_ID.asc)
    export AWS_SECRET_ACCESS_KEY=$(gpg -d --quiet ~/.adzerk/secrets/candera/AWS_SECRET_ACCESS_KEY.asc)
    export ADZERK_SLACK_TOKEN=$(zecret ADZERK_SLACK_TOKEN)
    export CLUBHOUSE_API_TOKEN=$(gpg -d --quiet ~/.adzerk/secrets/candera/CLUBHOUSE_API_TOKEN.asc)
}

# alias zc='zerkenv -s clear'
# alias zs='zerkenv -s'
# alias zl='zerkenv -l'

alias adzerk_sqlcmd='sqlcmd -S $ADZERK_MSQL_HOSTNAME -U $ADZERK_MSQL_USER -P $ADZERK_MSQL_PASSWORD -d adzerk'

function wangdera_creds() {
    eval $(gpg -d ~/wangdera-candera-aws-creds.gpg)
}

# ecl is a little wrapper for emacsclient -nw, since passing switches
# via the environment variable doesn't work very well.
export EDITOR=ecl

# # Lets me use jenv without having be root
# export JENV_ROOT=/usr/local/opt/jenv
# eval "$(jenv init -)"

function jenv ()
{
    local JH=$(/usr/libexec/java_home -v $1)
    export JAVA_HOME=$JH
    echo JAVA_HOME=$JH
}

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash

# emacs-vterm support
if [[ $INSIDE_EMACS == "vterm" ]]
then
    cd() {
        builtin cd "$@" || return
        [ "$OLDPWD" = "$PWD" ] || echo -e "\033]51;$(pwd)\033\\"
    }
fi
