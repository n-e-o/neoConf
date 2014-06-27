#!/bin/bash

# Get the script directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install necessary packages
sudo apt-get install git emacs zsh ssh

# Get oh-my-zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

function installFiles()
{
	# Install all home local configuration files
	cp -r ${script_dir}/homeDirFiles/. ~/
}

# Copy all local home files
installFiles

# Set Zsh as best shell ever
chsh -s `which zsh`

# Set Cinnamon theme
gsettings set org.cinnamon.theme name 'Dark_Void'
