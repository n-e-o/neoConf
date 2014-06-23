#!/bin/bash

# Get the script directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install necessary packages
sudo apt-get install git emacs zsh 

# Get oh-my-zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

function installFiles()
{
	# Install all home local configuration files
	cp -r ${script_dir}/homeDirFiles/. ~/
}

installFiles
