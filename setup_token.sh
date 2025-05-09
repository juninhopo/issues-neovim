#!/bin/bash

echo "Setting up GitHub token for issues-neovim plugin"
echo "==============================================="
echo ""
echo "This script will prompt you for your GitHub Personal Access Token and save it"
echo "to the appropriate location for the issues-neovim plugin."
echo ""
echo "If you don't have a token yet, create one at: https://github.com/settings/tokens"
echo "Make sure it has the 'repo' scope enabled."
echo ""

read -p "Enter your GitHub Personal Access Token: " token

if [ -z "$token" ]; then
  echo "No token provided. Exiting."
  exit 1
fi

# Create config directory
mkdir -p ~/.config/issues-neovim

# Save token to file
echo "$token" > ~/.config/issues-neovim/token

# Set permissions
chmod 600 ~/.config/issues-neovim/token

echo ""
echo "✅ Token saved to ~/.config/issues-neovim/token"
echo ""
echo "To use the token immediately in your current session, run:"
echo "export GITHUB_TOKEN=$token"
echo ""
echo "You can now restart Neovim and try the plugin again." 