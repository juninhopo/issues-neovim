#!/bin/bash

# Installation script for issues-neovim
# This script installs the CLI and configures the Neovim integration

set -e

# Colors for better visualization
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing Issues-Neovim CLI and plugin...${NC}"

# Check requirements
command -v node >/dev/null 2>&1 || { 
  echo -e "${RED}Error: Node.js is not installed. Please install Node.js to continue.${NC}"
  exit 1
}

command -v npm >/dev/null 2>&1 || { 
  echo -e "${RED}Error: npm is not installed. Please install npm to continue.${NC}"
  exit 1
}

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
npm install

# Install CLI globally
echo -e "${YELLOW}Installing CLI globally...${NC}"
npm link

# Check if Neovim config directory exists
NVIM_CONFIG_DIR="${HOME}/.config/nvim"
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
  echo -e "${YELLOW}Neovim configuration directory not found at $NVIM_CONFIG_DIR.${NC}"
  echo -e "${YELLOW}You'll need to configure the plugin manually.${NC}"
  exit 0
fi

# Check if plugins directory exists, create if not
PLUGINS_DIR="${NVIM_CONFIG_DIR}/lua/plugins"
if [ ! -d "$PLUGINS_DIR" ]; then
  echo -e "${YELLOW}Creating plugins directory at $PLUGINS_DIR...${NC}"
  mkdir -p "$PLUGINS_DIR"
fi

# Copy integration file
echo -e "${YELLOW}Installing Neovim plugin...${NC}"
cp integrations/issues-neovim.lua "$PLUGINS_DIR/"

# Check if user has Lazy.nvim
if [ -d "${NVIM_CONFIG_DIR}/lazy" ]; then
  echo -e "${GREEN}Lazy.nvim detected!${NC}"
  echo -e "${YELLOW}To configure the plugin, you can edit ${PLUGINS_DIR}/issues-neovim.lua.${NC}"
else
  echo -e "${YELLOW}Lazy.nvim not detected. The plugin has been installed, but you'll need to configure your plugin manager manually.${NC}"
fi

# GitHub token configuration
echo -e "${YELLOW}Configuring GitHub token...${NC}"
read -p "Do you want to configure a GitHub token now? (y/n): " configure_token

if [[ "$configure_token" == "y" || "$configure_token" == "Y" ]]; then
  read -p "Enter your GitHub token: " github_token
  
  # Add token to config file
  echo "vim.g.github_token = \"$github_token\"" >> "${NVIM_CONFIG_DIR}/init.lua"
  echo -e "${GREEN}Token configured successfully!${NC}"
else
  echo -e "${YELLOW}No problem! You can configure the token later.${NC}"
  echo -e "${YELLOW}Add 'export GITHUB_TOKEN=\"your_token\"' to your .bashrc or .zshrc file${NC}"
  echo -e "${YELLOW}Or add 'vim.g.github_token = \"your_token\"' to your init.lua${NC}"
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}To use the CLI, run 'issues-neovim' in the terminal.${NC}"
echo -e "${GREEN}In Neovim, use the <leader>gi shortcut to open the interface.${NC}"
echo -e "${YELLOW}Restart Neovim or run :Lazy sync to finish the installation.${NC}" 