#!/bin/sh

#
# Install all the required dependencies for building and deploying Firefox for iOS
# Assumes you already have git otherwise you wouldn't have this setup script
#
# run ./setup_build_tools.sh from the command line to run
#

#
# Check if XCode Command Line Tools are installed
#
which -s xcode-select
if [[ $? != 0 ]] ; then
	echo "Installing XCode Command Line Tools"
	# Install XCode Command Line Tools
	xcode-select --install
else
	echo "XCode Command Line Tools already installed"
fi

#
# Check if Homebrew is installed
#
which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
	echo "Installing Homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
	echo "Homebrew already installed, but will update to get latest"
	brew update
fi

#
# Check if virtualenv is installed
#
which -s virtualenv
if [[ $? != 0 ]] ; then
    # Install virtualenv
	echo "Installing vitualenv"
    pip3 install virtualenv
else
	echo "virtualenv already installed"
fi

#
# Check if Node is installed
#
which -s node
if [[ $? != 0 ]] ; then
    # Install Node
    echo "Installing Node.js"
    brew install node
else
	echo "Node.js already installed"
fi

#
# Check if swiftlint is installed
#
which -s swiftlint
if [[ $? != 0 ]] ; then
    # Install swiftlint
	echo "Installing swiftlint."
    brew install swiftlint
else
	echo "Swiftlint already installed"
fi
