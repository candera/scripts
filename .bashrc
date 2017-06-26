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

# Adzerk environment setup
adzerk_env() {
    export ADZERK_ENV=$1
    if [[ -z "$ADZERK_ENV" ]]; then
        ADZERK_ENV=staging
    fi
    eval "$(gpg -d ~/.adzerk.asc)"

    export AWS_SECRET_ACCESS_KEY_ID=${ADZERK_AWS_SECRET_KEY}
    export AWS_SECRET_ACCESS_KEY=${ADZERK_AWS_SECRET_KEY}
    export AWS_ACCESS_KEY_ID=${ADZERK_AWS_ACCESS_KEY}
    export AWS_ACCESS_KEY=${ADZERK_AWS_ACCESS_KEY}
    export AWS_SECRET_KEY_ID=${ADZERK_AWS_SECRET_KEY}
    export AWS_SECRET_KEY=${ADZERK_AWS_SECRET_KEY}
    export ADZERK_REPO_PATH=~/adzerk/adzerk
    export ADZERK_DOCKER_MONO_PATH=~/adzerk/mono-docker
    export PATH=$PATH:~/adzerk/cli-tools/micha:~/adzerk/cli-tools/scripts

    while true; do
        if [[ "$1" == "" ]]; then
            break
        fi

        local ENV_FILE=~/.adzerk-${1}.asc
        if [[ -e $ENV_FILE ]]; then
            echo "Loading environment configuration '$1' from $ENV_FILE"
            eval "$(gpg -d $ENV_FILE)"
        else
            echo -e "\033[0;31mUnknown environment '$1'\033[0m"
        fi

        shift
    done
}

function prompt_callback () {
    if [[ -n "${ADZERK_ENV}" ]]; then
        if [[ "${ADZERK_ENV}" == "prod" ]]; then
            local COLOR=${DimRedBg}
        else
            local COLOR=${DimBlueBg}
        fi
        echo " ${COLOR}[${ADZERK_ENV} ($ADZERK_MSQLCLI_USER)]${ResetColor}"
    fi
}

# This prevents Adzerk's Docker setup from picking up on settings like the .bashrc from the host.
export DOCKER_USER_MODE=no

# Set background color in iTerm

background () {
    # Format: rrggbb in hex, e.g. ff0088
    local COLOR=$1
    if [[ -z "$COLOR" ]]; then
        COLOR=$(printf '%02X%02X%02X' $(($RANDOM / 700)) $(($RANDOM / 700)) $(($RANDOM / 700)))
        echo "Setting background to 0x${COLOR}"
    fi
    # Reference https://www.iterm2.com/documentation-escape-codes.html
    echo -e "\033]Ph${COLOR}\033\\"
}
