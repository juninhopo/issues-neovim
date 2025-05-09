const { Octokit } = require('octokit');
const inquirer = require('inquirer');
const chalk = require('chalk');

// Function to initialize GitHub API
async function initOctokit(requireAuth = false) {
  // Check if token exists
  let token = process.env.GITHUB_TOKEN;
  
  if (!token && requireAuth) {
    const response = await inquirer.prompt([
      {
        type: 'password',
        name: 'token',
        message: 'Enter your GitHub personal access token:',
        validate: input => input.length > 0 ? true : 'Token is required for this operation'
      }
    ]);
    token = response.token;
    console.log(chalk.yellow('Tip: To avoid entering the token every time, set the GITHUB_TOKEN environment variable.'));
  } else if (!token && !requireAuth) {
    console.log(chalk.blue('Accessing GitHub without authentication. Some operations may be limited and rate limits are lower.'));
  }
  
  return new Octokit({ 
    auth: token || undefined,
    request: {
      retries: 3,
      retryAfter: 1
    }
  });
}

// Fetch issues for a repository
async function fetchIssues(owner, repo, options = {}) {
  const octokit = await initOctokit(false);
  const state = options.state || 'open';
  const perPage = options.perPage || 10;
  
  const { data: issues } = await octokit.rest.issues.listForRepo({
    owner,
    repo,
    state,
    per_page: perPage
  });
  
  return issues;
}

// Fetch a specific issue
async function fetchIssue(owner, repo, issueNumber) {
  const octokit = await initOctokit(false);
  
  const { data: issue } = await octokit.rest.issues.get({
    owner,
    repo,
    issue_number: parseInt(issueNumber)
  });
  
  return issue;
}

// Fetch comments for an issue
async function fetchComments(owner, repo, issueNumber) {
  const octokit = await initOctokit(false);
  
  const { data: comments } = await octokit.rest.issues.listComments({
    owner,
    repo,
    issue_number: parseInt(issueNumber)
  });
  
  return comments;
}

// Create a new issue
async function createIssue(owner, repo, title, body) {
  const octokit = await initOctokit(true);
  
  const { data: issue } = await octokit.rest.issues.create({
    owner,
    repo,
    title,
    body
  });
  
  return issue;
}

// Add a comment to an issue
async function createComment(owner, repo, issueNumber, body) {
  const octokit = await initOctokit(true);
  
  const { data: comment } = await octokit.rest.issues.createComment({
    owner,
    repo,
    issue_number: parseInt(issueNumber),
    body
  });
  
  return comment;
}

// Check API rate limits
async function checkRateLimits() {
  const octokit = await initOctokit(false);
  
  const { data } = await octokit.rest.rateLimit.get();
  
  return data.rate;
}

module.exports = {
  initOctokit,
  fetchIssues,
  fetchIssue,
  fetchComments,
  createIssue,
  createComment,
  checkRateLimits
}; 