export PATH=/usr/local/Cellar/ruby/1.9.3-p194/bin/:$PATH:~/bin
source ~/projects/etc/bash/git_prompt.sh

# Enable colors for ls
export CLICOLOR=true

[[ -s "/Users/candera/.rvm/scripts/rvm" ]] && source "/Users/candera/.rvm/scripts/rvm"  # This loads RVM into a shell session.

# gpg-agent insanity
keychain -q
source ~/.keychain/`hostname`-sh-gpg
