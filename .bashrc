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

# # Setup for brew version of bash-git-prompt
# GIT_PROMPT_FETCH_REMOTE_STATUS=0   # avoid fetching remote status
# if [ -f "/usr/local/opt/bash-git-prompt/share/gitprompt.sh" ]; then
#     __GIT_PROMPT_DIR="/usr/local/opt/bash-git-prompt/share"
#     source "/usr/local/opt/bash-git-prompt/share/gitprompt.sh"
# fi

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

alias python=python3

if [[ -f ~/local.bashrc ]]; then
    source ~/local.bashrc
fi

# Settings for boot
# export BOOT_JVM_OPTIONS="-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Xmx2g -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -Xverify:none -XX:-OmitStackTraceInFastThrow"

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

	local NOW=$(date +%s)

	if [[ ! -a ~/.last-sso-check || $(( $NOW - $(cat ~/.last-sso-check) )) -gt 600 ]]
	then
	    if ! (aws sts get-caller-identity >/dev/null 2>/dev/null)
	    then
		LOGIN_STATUS="${Yellow}X${ResetColor} "
	    fi
	    echo $NOW > ~/.last-sso-check
	fi
        echo -e " ${LOGIN_STATUS}[${COLOR}(${ADZERK_MSQL_USER}@${ADZERK_MSQL_HOSTNAME})${ResetColor} ${DimBlueBg}$(echo ${ZERKENV_MODULES})${ResetColor}]"
    fi
}

# If I want paging in the output, I'll do it myself
export AWS_PAGER=""

# Gives auto complete in the aws shell (run aws with no args)
export AWS_CLI_AUTO_PROMPT=on-partial

# This prevents Adzerk's Docker setup from picking up on settings like the .bashrc from the host.
export DOCKER_USER_MODE=no

export ZERKENV_BUCKET=zerkenv
export ZERKENV_REGION=us-east-1

export PATH=$PATH:~/adzerk/zerkenv

function zsso() {
    local ESCALATE NO_PROFILE ASK IS_NUMBER GET_PROFILE
    # Automate popping a browser open to log in via SSO, only if I'm not already
    # logged in.

    if [[ -z "$AWS_PROFILE" ]];
    then
	NO_PROFILE=y
    fi

    if [[ "$1" == "--ask" ]]
    then
	ASK=y
    fi

    if [[ "$1" =~ [0-9]+ ]]
    then
	IS_NUMBER=y
    fi

    GET_PROFILE=$(if [[ -n $NO_PROFILE || -n $ASK || -n $IS_NUMBER ]]; then echo yes; fi)

    if [[ -n $GET_PROFILE ]]
    then
	if [[ -z "$1" || -n $ASK || -n $IS_NUMBER ]] 
	then
	    PROFILES=$(mktemp)
	    cat ~/.aws/config \
		| grep profile \
		| sed -nr 's/\[profile (.*)\]/\1/p' \
		| cat <(echo "jha-escalated") - \
		| cat -n \
		      > $PROFILES
	    if [[ -z $IS_NUMBER ]]
	    then
		cat $PROFILES | column -t
		read -p "> "
	    else
		REPLY=$1
	    fi
	    export AWS_PROFILE=$(cat $PROFILES \
				     | cut -f 2 \
				     | tail -n +$REPLY \
				     | head -n 1)
	else     
	    export AWS_PROFILE=$1
	fi
    fi

    if [[ $AWS_PROFILE =~ "jha-escalated" ]]
    then
	echo "Escalation requested"
	ESCALATE=y
	AWS_PROFILE=jha-devops-readonly
    fi

    aws sts get-caller-identity >/dev/null 2>/dev/null \
	|| aws sso login || return 1

    eval $(aws configure export-credentials --profile $AWS_PROFILE --format env)

    if [[ "$ESCALATE" == "y" ]]
    then
	if [[ -n $KEVEL_TICKET ]]
	then
	    read -p "Escalation story [$KEVEL_TICKET]: "
	else
	    read -p "Escalation story: "
	fi
	export KEVEL_TICKET=${REPLY:-$KEVEL_TICKET}
	eval $(~/adzerk/infrastructure/scripts/pacs -t $KEVEL_TICKET -e)
	unset AWS_PROFILE
	AWS_DISPLAY_PROFILE=jha-escalated
    fi

    # It's a good time to grab the secret since we may not have been able to get it previously
    if [[ -z $ADZERK_SLACK_TOKEN ]]
    then
	export ADZERK_SLACK_TOKEN=$(zecret ADZERK_SLACK_TOKEN 2> /dev/null)
    fi
}

eval "$(jenv init -)"

function zerk() {
    # eval $(gpg -d --quiet ~/.zerkenv/@aws-creds.sh.asc)

    zsso $1 || return 1

    if ! ssh-add -l | grep '\.ssh/adzerk\.pem' > /dev/null
    then
        ssh-add ~/.ssh/adzerk.pem
    fi
    export ADZERK_ENV=" "
    export KEVEL_JHA_READONLY_PROFILE=jha-devops-readonly
    export PATH=$PATH:~/adzerk/cli-tools/scripts:~/adzerk/teammgmt/bin:~/adzerk/teammgmt/infrastructure/bin:~/adzerk/:~/adzerk/infrastructure/scripts
    
    # export AWS_ACCESS_KEY_ID=$(gpg -d --quiet ~/.adzerk/secrets/candera/AWS_ACCESS_KEY_ID.asc)
    # export AWS_SECRET_ACCESS_KEY=$(gpg -d --quiet ~/.adzerk/secrets/candera/AWS_SECRET_ACCESS_KEY.asc)

    export ADZERK_SLACK_TOKEN=$(zecret ADZERK_SLACK_TOKEN)
    export SHORTCUT_API_TOKEN=$(gpg -d --quiet ~/.adzerk/secrets/candera/CLUBHOUSE_API_TOKEN.asc)

    export NVM_DIR="$HOME/.nvm"
    [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
    [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

    export KEVEL_SUPPRESS_HOOK_WARNING='y'

    # If this doesn't work, you might need to do something like `jenv add /usr/local/Cellar/openjdk@17/17.0.7/` possibly followed by `hash -r`
    jenv shell 17.0.8

    source ~/adzerk/teammgmt/bin/.fns
}

alias geir='zerk && nvm use 14.17.3 && cd ~/adzerk/geir && background purple'
alias api-proxy='zerk && cd ~/adzerk/api-proxy && background blue'
alias hairstyles='zerk && cd ~/adzerk/adzerk && background grey'
alias publisher='zerk && cd ~/adzerk/publisher && background green'
alias integration-tests='zerk && cd ~/adzerk/integration-tests && background red'
alias teammgmt='zerk && cd ~/adzerk/teammgmt && background white'
alias snotra='zerk  && cd ~/adzerk/snotra && background teal'
alias audit-log-writer='zerk && cd ~/adzerk/audit-log-writer && background forest'
alias getsmarterandmakestuff='wangdera_creds && cd ~/projects/getsmarterandmakestuff.com && background 0x010221'

alias vmt='background 000033 && title VMT && export VMT_DEV_OPEN_WINDOW_EARLY=1 VMT_DEV_SHOW_TEST_WINDOW && cd ~/projects/vmt && jenv 16'

function wangdera_creds() {
    eval $(gpg -d ~/wangdera-candera-aws-creds.gpg)
}

# ecl is a little wrapper for emacsclient -nw, since passing switches
# via the environment variable doesn't work very well.
export EDITOR=ecl

# # Lets me use jenv without having be root
# export JENV_ROOT=/usr/local/opt/jenv
# eval "$(jenv init -)"

# function jenv ()
# {
#     if [[ $1 == "17" ]]
#     then
# 	export JAVA_HOME=/usr/local/Cellar/openjdk/17.0.1/
#     else
# 	local JH=$(/usr/libexec/java_home -v $1)
# 	export JAVA_HOME=$JH
#     fi
#     echo JAVA_HOME=$JAVA_HOME
# }

# Set default to 17
# jenv 17

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash

# emacs-vterm support
if [[ $INSIDE_EMACS == "vterm" ]]
then
    cd() {
        builtin cd "$@" || return
        [ "$OLDPWD" = "$PWD" ] || echo -e "\033]51;$(pwd)\033\\"
    }
fi

# For remote access, e.g. TRAMP, don't confuse the emacs
case "$TERM" in
    "dumb")
        export PS1="> "
        ;;
    # xterm*|rxvt*|eterm*|screen*)
    #     tty -s && export PS1="some crazy prompt stuff"
    #     ;;
esac

# Bash completion
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# Trying this as an alternative to bash-git-prompy
source /usr/local/opt/gitstatus/gitstatus.prompt.sh

function echoc() {
  echo -e "${1}$2${ResetColor}" | sed 's/\\\]//g'  | sed 's/\\\[//g'
}

function prompt() {
    local IS_JHA
    local TICKET
    local PROFILE=${AWS_PROFILE:=$AWS_DISPLAY_PROFILE}
    if [[ -n $PROFILE ]]
    then
	if [[ $PROFILE =~ jha- ]]
	then
	    IS_JHA=yes
	fi
    fi

    if [[ -n "${ADZERK_ENV}" || -n "${PROFILE}" ]]
    then
	echo -ne "["
        if [[ $ADZERK_MSQL_HOSTNAME =~ \.prod.opzerk.com || "$IS_JHA" == "yes" ]]
        then
            echo -ne "\e[1;41m"
        else
            echo -ne "\e[1;44m"
        fi

	if [[ -n $KEVEL_TICKET ]]
	then
	    TICKET="($KEVEL_TICKET)"
	fi

	echo -ne "${PROFILE}$TICKET:${ADZERK_MSQL_USER}@${ADZERK_MSQL_HOSTNAME}\e[0m] "
    fi

    gitstatus_prompt_update
    
    if [[ -n $GITSTATUS_PROMPT ]]
    then
	echo -e "{${GITSTATUS_PROMPT:+$GITSTATUS_PROMPT}}"
    fi
}

# I had a hell of a time with this. Bash wants escape sequences
# surrounded by `\[` and `\]` to indicate they are unprintable, but I
# get different behavior when those are used in PROMPT_COMMAND vs.
# PS1, resulting in literal \[ and \] characters in the prompt.
PROMPT_COMMAND=prompt
PS1='\[\e[33m\]$(dirs +0)\[\e[0m\] \[\e[32m\]$(whoami)@$(cat ~/.machine-name)\[\e[0m\] \[\e[97;1m\]$\[\e[0m\] '

function gitstatus_help() {
    echo "master	current branch
#v1	HEAD is tagged with v1; not shown when on a branch
@5fc6fca4	current commit; not shown when on a branch or tag
⇣1	local branch is behind the remote by 1 commit
⇡2	local branch is ahead of the remote by 2 commits
⇠3	local branch is behind the push remote by 3 commits
⇢4	local branch is ahead of the push remote by 4 commits
*5	there are 5 stashes
merge	merge is in progress (could be some other action)
~6	there are 6 merge conflicts
+7	there are 7 staged changes
!8	there are 8 unstaged changes
?9	there are 9 untracked files"
}

function aws_console () {
    ( zerk 2
      open `pacs -l`
    )
}
