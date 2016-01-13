#!/bin/sh

# 
# Install all the required dependencies for building and deploying Firefox for iOS
# Assumes you already have git otherwise you wouldn't have this setup script
#
# run ./setup.sh from the command line to run
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
	echo "Homebrew already installed"
fi

#
# Check if python is installed
#
if [ ! -e $(python -c 'from distutils.sysconfig import get_makefile_filename as m; print m()') ]; then 
	# Install python
	echo "Installing python"
	brew install python
else
	echo "python already installed"
fi

# 
# Check if virtualenv is installed
#
which -s virtualenv
if [[ $? != 0 ]] ; then
    # Install virtualenv
	echo "Installing vitualenv"
    pip install virtualenv
else
	echo "virtualenv already installed"
fi

if [ ! -d /usr/local/Cellar/imagemagick ] ; then
	echo "installing imagemagick"
	brew install imagemagick
else
	echo "imagemagick already installed"
fi

#
# Check is Carthage is installed
#
which -s carthage
if [[ $? != 0 ]] ; then
    # Install Carthage
	echo "Installing Carthage"
    brew install carthage
else
	echo "Carthage already installed"
fi

#
# Check if fastlane is installed
#
which -s fastlane
if [[ $? != 0 ]] ; then
    # Install fastlane
	echo "Installing fastlane."
    sudo gem install fastlane
    fastlane init
else
	echo "fastlane already installed"
fi

