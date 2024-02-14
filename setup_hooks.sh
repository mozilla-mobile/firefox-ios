#!/bin/bash

# Check if the .git/hooks directory exists
if [ ! -d ".git/hooks" ]; then
  echo ".git/hooks directory does not exist. Creating it now."
  mkdir -p .git/hooks
fi

# Copy all custom hooks from hooks/ to .git/hooks/
cp hooks/* .git/hooks/

# Ensure the hooks are executable
chmod +x .git/hooks/*

echo "Git hooks have been installed successfully."