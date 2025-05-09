-- Debug script to test GitHub API connectivity
local curl = require("plenary.curl")
local token_loader = require("issues-neovim.token_loader")

-- Define a simple function to make a test API call
local function test_api_call()
  -- Get the token
  local token = token_loader.load_token()
  
  if not token or token == "" then
    print("[ERROR] No GitHub token found. Please set the GITHUB_TOKEN environment variable or configure it in the plugin.")
    return false
  end
  
  print("[INFO] Token found. Testing API connection...")
  
  -- Make a simple API call to GitHub to test authentication
  local headers = {
    Accept = "application/vnd.github.v3+json",
    ["User-Agent"] = "Neovim-IssuesNeovim-Debug",
    Authorization = "token " .. token
  }
  
  local response = curl.get("https://api.github.com/user", {
    headers = headers
  })
  
  if not response or response.status < 200 or response.status >= 300 then
    print("[ERROR] API request failed: " .. (response and response.status or "Unknown error"))
    print("[ERROR] Error details: " .. (response and response.body or "No response"))
    return false
  end
  
  print("[SUCCESS] API connection successful. Response status: " .. response.status)
  print("[INFO] Your GitHub username: " .. require("plenary.json").decode(response.body).login)
  return true
end

-- Run the test
local success = test_api_call()
print("[DEBUG] API test result: " .. (success and "SUCCESS" or "FAILURE"))

-- Check if token is being properly loaded
print("[DEBUG] Token source check:")
print("  Environment variable: " .. (os.getenv("GITHUB_TOKEN") and "PRESENT" or "MISSING"))
print("  Home file (~/.githubtoken): " .. (io.open(vim.fn.expand("~/.githubtoken"), "r") and "PRESENT" or "MISSING"))
print("  Config file (~/.config/issues-neovim/token): " .. (io.open(vim.fn.expand("~/.config/issues-neovim/token"), "r") and "PRESENT" or "MISSING")) 