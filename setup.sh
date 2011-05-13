#!/bin/bash

# Fail immediately if anything doesn't work
set -e

sudo apt-get -y install aptitude
sudo aptitude -y install emacs git build-essential emacs-goodies-el emacs-goodies-extra-el compizconfig-settings-manager xsane ruby1.8 ruby1.8-dev wmctrl kdiff3 compiz-fusion-plugins-extra vlc vlc-plugin-pulse curl maven2

# Get my emacs setup going
mkdir -p ~/projects
git clone https://github.com/candera/emacs.git ~/projects/emacs
~/projects/emacs/setup

# Set up Leiningen
mkdir -p ~/bin
echo "export PATH=$PATH:~/bin" >> ~/.bashrc
source ~/.bashrc
curl -k -o ~/bin/lein https://github.com/technomancy/leiningen/raw/stable/bin/lein 
chmod u+x ~/bin/lein
lein self-install
