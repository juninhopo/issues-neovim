-- Issue Creation module
local api = require("issues-neovim.api")

local M = {}

-- Open the issue creation UI
function M.open(opts)
  -- First detect repository if not provided
  if not opts.owner or not opts.repo then
    local repo_info = api.detect_repository()
    if repo_info.detected then
      opts.owner = repo_info.owner
      opts.repo = repo_info.repo
    end
  end
  
  -- Verify token is available
  if not opts.token or opts.token == "" then
    vim.notify("GitHub token is required to create issues. Please set it in your configuration.", vim.log.levels.ERROR)
    return
  end
  
  -- Prompt for issue title
  vim.ui.input({
    prompt = "Issue title: ",
  }, function(title)
    if not title or title == "" then
      vim.notify("Issue creation cancelled - title is required", vim.log.levels.WARN)
      return
    end
    
    -- Create a temporary buffer for the description
    create_issue_buffer(title, opts)
  end)
end

-- Create a buffer for issue description
local function create_issue_buffer(title, opts)
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, true)
  
  -- Set initial content with template
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# Issue Description",
    "#",
    "# Write a detailed description of the issue here.",
    "# Lines starting with # will be ignored.",
    "#",
    "# Repository: " .. opts.owner .. "/" .. opts.repo,
    "# Title: " .. title,
    "",
    "## Description",
    "",
    "<!-- Describe the issue in detail -->",
    "",
    "## Steps to Reproduce",
    "",
    "<!-- If applicable, provide steps to reproduce the issue -->",
    "",
    "## Expected Behavior",
    "",
    "<!-- What did you expect to happen? -->",
    "",
    "## Current Behavior",
    "",
    "<!-- What actually happened? -->",
    "",
  })
  
  -- Open buffer in a new window
  local cmd = "botright split"
  vim.cmd(cmd)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, 20)
  
  -- Set buffer options
  vim.api.nvim_buf_set_name(buf, "GITHUB_ISSUE.md")
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Create commands for submitting or canceling
  vim.api.nvim_create_user_command("IssueSubmit", function()
    submit_issue(buf, title, opts)
  end, {})
  
  vim.api.nvim_create_user_command("IssueCancel", function()
    vim.cmd("bdelete!")
    vim.notify("Issue creation cancelled", vim.log.levels.INFO)
  end, {})
  
  -- Create autocommand for buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = buf,
    callback = function()
      pcall(vim.api.nvim_del_user_command, "IssueSubmit")
      pcall(vim.api.nvim_del_user_command, "IssueCancel")
    end,
    once = true
  })
  
  -- Show help message
  vim.notify(
    "Write your issue description and use :IssueSubmit to create or :IssueCancel to abort",
    vim.log.levels.INFO
  )
end

-- Extract body content from buffer, removing comments
local function extract_body(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local body_lines = {}
  
  for _, line in ipairs(lines) do
    -- Skip comment lines (lines starting with #)
    if not line:match("^%s*#") and not line:match("^%s*<!%-%-") and not line:match("%-%->%s*$") then
      table.insert(body_lines, line)
    end
  end
  
  return table.concat(body_lines, "\n")
end

-- Submit the issue to GitHub
local function submit_issue(buf, title, opts)
  -- Extract body content
  local body = extract_body(buf)
  
  -- Trim leading/trailing whitespace
  body = body:gsub("^%s+", ""):gsub("%s+$", "")
  
  -- Check if body is empty
  if body == "" then
    vim.notify("Issue description cannot be empty", vim.log.levels.ERROR)
    return
  end
  
  -- Close buffer
  vim.cmd("bdelete " .. buf)
  
  -- Show loading message
  vim.notify("Creating issue...", vim.log.levels.INFO)
  
  -- Create issue via API
  api.create_issue({
    token = opts.token,
    owner = opts.owner,
    repo = opts.repo,
    title = title,
    body = body
  }, function(issue, err)
    if err or not issue then
      vim.notify("Error creating issue: " .. (err or "Unknown error"), vim.log.levels.ERROR)
      return
    end
    
    vim.notify(
      string.format("Issue #%d created successfully: %s", issue.number, issue.html_url),
      vim.log.levels.INFO
    )
    
    -- Open the issue in the issue view
    local issue_view = require("issues-neovim.issue_view")
    issue_view.open(issue.number, opts)
  end)
end

return M 