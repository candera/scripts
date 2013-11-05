export PATH=/usr/local/Cellar/ruby/1.9.3-p194/bin/:$PATH:~/bin
source ~/projects/etc/bash/git_prompt.sh

# Enable colors for ls
export CLICOLOR=true

[[ -s "/Users/candera/.rvm/scripts/rvm" ]] && source "/Users/candera/.rvm/scripts/rvm"  # This loads RVM into a shell session.

# gpg-agent insanity
keychain -q
source ~/.keychain/`hostname`-sh-gpg

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
source ~/projects/bash-git-prompt/gitprompt.sh
