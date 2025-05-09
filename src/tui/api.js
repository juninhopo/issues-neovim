const { Octokit } = require('octokit');
const { updateStatus, updateIssuesList, updateIssueDetails } = require('./ui');

// Initialize GitHub API
async function initOctokit(state) {
  // For read-only operations on public repositories, token is optional
  if (!state.token && state.needsAuth) {
    state.token = await require('./prompts').promptGitHubToken(state);
  }
  
  // Return Octokit instance
  return new Octokit({ 
    auth: state.token || undefined
  });
}

// Fetch issues from GitHub
async function fetchIssues(state, ui) {
  state.loading = true;
  updateStatus(ui, 'Fetching issues...', 'info');
  
  try {
    const octokit = await initOctokit(state);
    
    const { data: issues } = await octokit.rest.issues.listForRepo({
      owner: state.owner,
      repo: state.repo,
      state: state.issueState,
      page: state.page,
      per_page: state.perPage,
      sort: 'updated',
      direction: 'desc'
    });
    
    state.issues = issues;
    state.loading = false;
    state.error = null;
    
    updateIssuesList(state, ui);
    updateStatus(ui, `Loaded ${issues.length} issues`, 'success');
    
    ui.screen.render();
  } catch (error) {
    state.loading = false;
    state.error = error.message;
    
    updateStatus(ui, `Error: ${error.message}`, 'error');
    ui.screen.render();
  }
}

// Search issues
async function searchIssues(state, ui) {
  if (!state.searchTerm) return;
  
  state.loading = true;
  updateStatus(ui, `Searching for "${state.searchTerm}"...`, 'info');
  
  try {
    const octokit = await initOctokit(state);
    
    const query = `repo:${state.owner}/${state.repo} ${state.searchTerm} in:title,body`;
    const { data } = await octokit.rest.search.issuesAndPullRequests({
      q: query,
      per_page: state.perPage
    });
    
    state.issues = data.items;
    state.loading = false;
    state.error = null;
    
    updateIssuesList(state, ui);
    updateStatus(ui, `Found ${data.items.length} results for "${state.searchTerm}"`, 'success');
    
    ui.screen.render();
  } catch (error) {
    state.loading = false;
    state.error = error.message;
    
    updateStatus(ui, `Search error: ${error.message}`, 'error');
    ui.screen.render();
  }
}

// Fetch issue details
async function fetchIssueDetails(state, ui, issueNumber) {
  state.loading = true;
  updateStatus(ui, `Fetching issue #${issueNumber} details...`, 'info');
  
  try {
    const octokit = await initOctokit(state);
    
    // Fetch issue details
    const { data: issue } = await octokit.rest.issues.get({
      owner: state.owner,
      repo: state.repo,
      issue_number: issueNumber
    });
    
    // Fetch comments
    const { data: comments } = await octokit.rest.issues.listComments({
      owner: state.owner,
      repo: state.repo,
      issue_number: issueNumber
    });
    
    state.loading = false;
    state.error = null;
    
    updateIssueDetails(state, ui, issue, comments);
    updateStatus(ui, `Loaded issue #${issueNumber} with ${comments.length} comments`, 'success');
    
    ui.screen.render();
  } catch (error) {
    state.loading = false;
    state.error = error.message;
    
    updateStatus(ui, `Error fetching issue details: ${error.message}`, 'error');
    ui.screen.render();
  }
}

// Create a new issue
async function createIssue(state, ui, title, body) {
  state.loading = true;
  updateStatus(ui, 'Creating issue...', 'info');
  
  try {
    const octokit = await initOctokit(state);
    
    const { data: issue } = await octokit.rest.issues.create({
      owner: state.owner,
      repo: state.repo,
      title,
      body
    });
    
    state.loading = false;
    state.error = null;
    
    updateStatus(ui, `Issue #${issue.number} created successfully`, 'success');
    require('./actions').refreshIssues(state, ui);
  } catch (error) {
    state.loading = false;
    state.error = error.message;
    
    updateStatus(ui, `Error creating issue: ${error.message}`, 'error');
    ui.screen.render();
  }
}

// Add a comment to an issue
async function createComment(state, ui, body) {
  if (!state.selectedIssue) return;
  
  state.loading = true;
  updateStatus(ui, 'Adding comment...', 'info');
  
  try {
    const octokit = await initOctokit(state);
    
    await octokit.rest.issues.createComment({
      owner: state.owner,
      repo: state.repo,
      issue_number: state.selectedIssue.number,
      body
    });
    
    state.loading = false;
    state.error = null;
    
    // Refresh issue details to show the new comment
    fetchIssueDetails(state, ui, state.selectedIssue.number);
    updateStatus(ui, 'Comment added successfully', 'success');
  } catch (error) {
    state.loading = false;
    state.error = error.message;
    
    updateStatus(ui, `Error adding comment: ${error.message}`, 'error');
    ui.screen.render();
  }
}

// Check API rate limits
async function checkApiLimits(state, ui) {
  state.loading = true;
  updateStatus(ui, 'Checking API rate limits...', 'info');
  
  try {
    const octokit = await initOctokit(state);
    
    const { data } = await octokit.rest.rateLimit.get();
    const { limit, remaining, reset } = data.rate;
    const resetDate = new Date(reset * 1000).toLocaleString();
    
    state.loading = false;
    
    // Show rate limit info in the details panel
    ui.components.issueDetails.setContent(
      `{bold}GitHub API Rate Limits{/bold}\n\n` +
      `{bold}Limit:{/bold} ${limit} requests per hour\n` +
      `{bold}Remaining:{/bold} ${remaining} requests\n` +
      `{bold}Reset Time:{/bold} ${resetDate}\n\n` +
      `Status: ${remaining < 10 ? '{red}Running low!{/red}' : '{green}OK{/green}'}`
    );
    
    updateStatus(ui, `API Limits: ${remaining}/${limit} remaining until ${resetDate}`, 'info');
    ui.screen.render();
  } catch (error) {
    state.loading = false;
    state.error = error.message;
    
    updateStatus(ui, `Error checking rate limits: ${error.message}`, 'error');
    ui.screen.render();
  }
}

module.exports = {
  initOctokit,
  fetchIssues,
  searchIssues,
  fetchIssueDetails,
  createIssue,
  createComment,
  checkApiLimits
}; 