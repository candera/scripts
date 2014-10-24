#!/bin/bash

# Fail immediately if anything doesn't work
set -e

function install_stuff {
    sudo apt-get -y install aptitude
    sudo aptitude -y install emacs git build-essential emacs-goodies-el emacs-goodies-extra-el \
	texinfo vlc vlc-plugin-pulse curl maven2 chromium-browser
}

function setup_emacs {
    mkdir -p ~/projects
    if [ ! -d ~/projects/emacs ]; then
	git clone https://github.com/candera/emacs.git ~/projects/emacs
	~/projects/emacs/setup
    fi
}

function setup_lein {
    mkdir -p ~/bin
    echo "export PATH=$PATH:~/bin" >> ~/.bashrc
    curl -k -o ~/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
    chmod u+x ~/bin/lein
    ~/bin/lein self-install
}

function setup_git {
    git config --global color.ui auto
    git config --global user.name "Craig Andera"
    git config --global user.email candera@wangdera.com
}

install_stuff
setup_emacs
setup_lein
setup_git
