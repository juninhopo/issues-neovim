#!/bin/bash

echo "Checking GitHub Token..."

# Check environment variable
if [ -n "$GITHUB_TOKEN" ]; then
  echo "✅ GITHUB_TOKEN environment variable is set"
else
  echo "❌ GITHUB_TOKEN environment variable is NOT set"
fi

# Check if token files exist
if [ -f ~/.githubtoken ]; then
  echo "✅ ~/.githubtoken file exists"
else
  echo "❌ ~/.githubtoken file does NOT exist"
fi

if [ -f ~/.config/issues-neovim/token ]; then
  echo "✅ ~/.config/issues-neovim/token file exists"
else
  echo "❌ ~/.config/issues-neovim/token file does NOT exist"
fi

# Test API connection
echo "Testing GitHub API connection..."
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "User-Agent: Neovim-IssuesNeovim-Debug" \
  https://api.github.com/user

if [ $? -eq 0 ]; then
  echo " ✅ API connection successful!"
else
  echo " ❌ API connection failed!"
fi 