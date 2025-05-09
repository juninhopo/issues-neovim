#!/usr/bin/env node

const blessed = require('blessed');
const contrib = require('blessed-contrib');
const { Octokit } = require('octokit');
const chalk = require('chalk');

// Global application state
const state = {
  issues: [],
  selectedIssue: null,
  selectedTab: 0,
  token: process.env.GITHUB_TOKEN || null,
  loading: false,
  error: null,
  page: 1,
  perPage: 30,
  issueState: 'open', // 'open' or 'closed'
  searchTerm: '',
  view: 'issues', // 'issues', 'details', 'create', 'comment'
  needsAuth: true,
  owner: 'issues-vim', // Default value
  repo: 'issues-vim'   // Default value
};

// Initialize the screen
const screen = blessed.screen({
  smartCSR: true,
  title: 'GitHub Issues CLI',
  dockBorders: true,
  fullUnicode: true,
});

// Layout principal usando grid
const grid = new contrib.grid({ rows: 12, cols: 12, screen: screen });

// Interface components
const header = grid.set(0, 0, 1, 12, blessed.box, {
  content: ' {bold}GitHub Issues CLI{/bold} ',
  tags: true,
  style: {
    fg: 'white',
    bg: 'blue',
  },
});

const tabs = grid.set(1, 0, 1, 12, blessed.listbar, {
  keys: true,
  mouse: true,
  style: {
    bg: 'black',
    item: {
      bg: 'black',
      fg: 'white',
      hover: {
        bg: 'blue',
      },
    },
    selected: {
      bg: 'blue',
      fg: 'white',
    },
  },
  commands: {
    'Open Issues': {
      keys: ['1'],
      callback: () => {
        state.issueState = 'open';
        state.selectedTab = 0;
        refreshIssues();
      },
    },
    'Closed Issues': {
      keys: ['2'],
      callback: () => {
        state.issueState = 'closed';
        state.selectedTab = 1;
        refreshIssues();
      },
    },
    'Search': {
      keys: ['3'],
      callback: promptSearch,
    },
    'Create Issue': {
      keys: ['4'],
      callback: promptCreateIssue,
    },
    'API Limits': {
      keys: ['5'],
      callback: checkApiLimits,
    },
    'Exit (q)': {
      keys: ['q'],
      callback: () => process.exit(0),
    },
  },
});

const issuesList = grid.set(2, 0, 8, 4, blessed.list, {
  keys: true,
  mouse: true,
  label: ' Issues ',
  border: {
    type: 'line',
  },
  style: {
    selected: {
      bg: 'blue',
      fg: 'white',
    },
    border: {
      fg: 'white',
    },
  },
  scrollbar: {
    ch: ' ',
    style: {
      bg: 'blue',
    },
  },
});

const issueDetails = grid.set(2, 4, 8, 8, blessed.box, {
  label: ' Issue Details ',
  content: 'Select an issue to view details',
  tags: true,
  border: {
    type: 'line',
  },
  style: {
    border: {
      fg: 'white',
    },
  },
  scrollable: true,
  alwaysScroll: true,
  scrollbar: {
    ch: ' ',
    style: {
      bg: 'blue',
    },
  },
});

const statusBar = grid.set(10, 0, 1, 12, blessed.text, {
  content: ' Loading...',
  tags: true,
  style: {
    fg: 'white',
    bg: 'blue',
  },
});

const helpBar = grid.set(11, 0, 1, 12, blessed.text, {
  content: ' {bold}↑/↓{/bold}: Navigate  {bold}Enter{/bold}: View Details  {bold}c{/bold}: Comment  {bold}r{/bold}: Refresh  {bold}5{/bold}: API Limits  {bold}q{/bold}: Exit',
  tags: true,
  style: {
    fg: 'white',
    bg: 'black',
  },
});

// Initialize GitHub API
async function initOctokit() {
  // For read-only operations on public repositories, token is optional
  if (!state.token && state.needsAuth) {
    state.token = await promptGitHubToken();
  }
  
  // Return Octokit instance
  return new Octokit({ 
    auth: state.token || undefined
  });
}

// Prompt for GitHub token
function promptGitHubToken() {
  return new Promise((resolve) => {
    const prompt = blessed.prompt({
      parent: screen,
      border: 'line',
      height: 'shrink',
      width: 'half',
      top: 'center',
      left: 'center',
      label: ' GitHub Token ',
      hidden: true,
      keys: true,
      vi: true,
    });

    prompt.input('Enter your GitHub personal access token (optional for viewing):', '', (err, value) => {
      prompt.destroy();
      screen.render();
      resolve(value);
    });

    screen.render();
  });
}

// Prompt for search
function promptSearch() {
  const prompt = blessed.prompt({
    parent: screen,
    border: 'line',
    height: 'shrink',
    width: 'half',
    top: 'center',
    left: 'center',
    label: ' Search Issues ',
    keys: true,
    vi: true,
  });

  prompt.input('Enter search term:', state.searchTerm, (err, value) => {
    if (value) {
      state.searchTerm = value;
      searchIssues();
    }
    prompt.destroy();
    screen.render();
  });

  screen.render();
}

// Prompt to create issue
function promptCreateIssue() {
  const form = blessed.form({
    parent: screen,
    keys: true,
    vi: true,
    left: 'center',
    top: 'center',
    width: '80%',
    height: 15,
    bg: 'black',
    border: {
      type: 'line',
    },
    label: ' Create New Issue ',
  });

  blessed.text({
    parent: form,
    left: 1,
    top: 1,
    content: 'Title:',
  });

  const titleInput = blessed.textbox({
    parent: form,
    name: 'title',
    inputOnFocus: true,
    left: 1,
    top: 2,
    height: 1,
    width: '95%',
    style: {
      fg: 'white',
      bg: 'black',
      focus: {
        bg: 'blue',
      },
    },
    border: {
      type: 'line',
    },
  });

  blessed.text({
    parent: form,
    left: 1,
    top: 4,
    content: 'Description:',
  });

  const bodyInput = blessed.textarea({
    parent: form,
    name: 'body',
    inputOnFocus: true,
    left: 1,
    top: 5,
    height: 5,
    width: '95%',
    style: {
      fg: 'white',
      bg: 'black',
      focus: {
        bg: 'blue',
      },
    },
    border: {
      type: 'line',
    },
  });

  const submitButton = blessed.button({
    parent: form,
    name: 'submit',
    content: 'Create',
    left: 1,
    top: 11,
    width: 10,
    height: 1,
    style: {
      bg: 'green',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  const cancelButton = blessed.button({
    parent: form,
    name: 'cancel',
    content: 'Cancel',
    left: 15,
    top: 11,
    width: 10,
    height: 1,
    style: {
      bg: 'red',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  submitButton.on('press', () => {
    const title = titleInput.getValue();
    const body = bodyInput.getValue();
    
    if (title.trim()) {
      form.destroy();
      createIssue(title, body);
    } else {
      showMessage('Title is required!', 'error');
    }
  });

  cancelButton.on('press', () => {
    form.destroy();
    screen.render();
  });

  titleInput.focus();
  screen.render();
}

// Function to comment on issue
function promptComment() {
  if (!state.selectedIssue) {
    showMessage('Select an issue first!', 'error');
    return;
  }

  const form = blessed.form({
    parent: screen,
    keys: true,
    vi: true,
    left: 'center',
    top: 'center',
    width: '80%',
    height: 11,
    bg: 'black',
    border: {
      type: 'line',
    },
    label: ` Comment on Issue #${state.selectedIssue.number} `,
  });

  blessed.text({
    parent: form,
    left: 1,
    top: 1,
    content: 'Comment:',
  });

  const commentInput = blessed.textarea({
    parent: form,
    name: 'comment',
    inputOnFocus: true,
    left: 1,
    top: 2,
    height: 5,
    width: '95%',
    style: {
      fg: 'white',
      bg: 'black',
      focus: {
        bg: 'blue',
      },
    },
    border: {
      type: 'line',
    },
  });

  const submitButton = blessed.button({
    parent: form,
    name: 'submit',
    content: 'Submit',
    left: 1,
    top: 8,
    width: 10,
    height: 1,
    style: {
      bg: 'green',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  const cancelButton = blessed.button({
    parent: form,
    name: 'cancel',
    content: 'Cancel',
    left: 15,
    top: 8,
    width: 10,
    height: 1,
    style: {
      bg: 'red',
      focus: {
        bg: 'blue',
      },
      hover: {
        bg: 'blue',
      },
    },
  });

  submitButton.on('press', () => {
    const comment = commentInput.getValue();
    
    if (comment.trim()) {
      form.destroy();
      createComment(comment);
    } else {
      showMessage('Comment cannot be empty!', 'error');
    }
  });

  cancelButton.on('press', () => {
    form.destroy();
    screen.render();
  });

  commentInput.focus();
  screen.render();
}

// Function to show messages
function showMessage(message, type = 'info') {
  const colors = {
    info: 'blue',
    success: 'green',
    error: 'red',
  };

  const messageBox = blessed.message({
    parent: screen,
    border: 'line',
    height: 'shrink',
    width: 'half',
    top: 'center',
    left: 'center',
    style: {
      border: {
        fg: colors[type],
      },
    },
  });

  messageBox.display(message, 3, () => {
    screen.render();
  });

  screen.render();
}

// function to update the screen title with the repository
function updateTitle() {
  const title = `GitHub Issues: ${state.owner}/${state.repo}`;
  screen.title = title;
  header.setContent(` {bold}${title}{/bold} `);
  screen.render();
}

// Functions to interact with GitHub API
async function fetchIssues() {
  try {
    state.loading = true;
    state.needsAuth = false; // Viewing issues is a read operation
    updateStatus(`Loading ${state.issueState} issues...`);
    screen.render();

    const octokit = await initOctokit();
    
    try {
      const { data: issues } = await octokit.rest.issues.listForRepo({
        owner: state.owner,
        repo: state.repo,
        state: state.issueState,
        per_page: state.perPage,
        page: state.page,
      });

      state.issues = issues;
      updateIssuesList();
      updateStatus(`${issues.length} issues loaded from ${state.owner}/${state.repo}`);
    } catch (apiError) {
      // Check if it's a rate limit error
      if (apiError.status === 403 && apiError.message.includes('API rate limit exceeded')) {
        state.needsAuth = true; // We need authentication to increase the limit
        showMessage('API rate limit exceeded. Please authenticate with a GitHub token.', 'error');
      } else {
        throw apiError; // Propagate other errors
      }
    }
  } catch (error) {
    state.error = error.message;
    updateStatus(`Error: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function searchIssues() {
  try {
    state.loading = true;
    state.needsAuth = false; // Searching issues is a read operation
    updateStatus(`Searching for "${state.searchTerm}"...`);
    screen.render();

    const octokit = await initOctokit();
    
    try {
      const { data: result } = await octokit.rest.search.issuesAndPullRequests({
        q: `repo:${state.owner}/${state.repo} ${state.searchTerm} in:title,body`,
        per_page: state.perPage,
        page: state.page,
      });

      state.issues = result.items;
      updateIssuesList();
      updateStatus(`${result.total_count} results found for "${state.searchTerm}" in ${state.owner}/${state.repo}`);
    } catch (apiError) {
      // Check if it's a rate limit error
      if (apiError.status === 403 && apiError.message.includes('API rate limit exceeded')) {
        state.needsAuth = true; // We need authentication to increase the limit
        showMessage('API rate limit exceeded. Please authenticate with a GitHub token.', 'error');
      } else {
        throw apiError; // Propagate other errors
      }
    }
  } catch (error) {
    state.error = error.message;
    updateStatus(`Error: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function fetchIssueDetails(issueNumber) {
  try {
    state.loading = true;
    state.needsAuth = false; // Viewing details is a read operation
    updateStatus(`Loading issue #${issueNumber} details...`);
    screen.render();

    const octokit = await initOctokit();
    
    try {
      const { data: issue } = await octokit.rest.issues.get({
        owner: state.owner,
        repo: state.repo,
        issue_number: issueNumber,
      });

      const { data: comments } = await octokit.rest.issues.listComments({
        owner: state.owner,
        repo: state.repo,
        issue_number: issueNumber,
        per_page: 100,
      });

      updateIssueDetails(issue, comments);
      updateStatus(`Issue #${issueNumber} details loaded from ${state.owner}/${state.repo}`);
    } catch (apiError) {
      // Check if it's a rate limit error
      if (apiError.status === 403 && apiError.message.includes('API rate limit exceeded')) {
        state.needsAuth = true; // We need authentication to increase the limit
        showMessage('API rate limit exceeded. Please authenticate with a GitHub token.', 'error');
      } else {
        throw apiError; // Propagate other errors
      }
    }
  } catch (error) {
    state.error = error.message;
    updateStatus(`Error: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function createIssue(title, body) {
  try {
    state.loading = true;
    state.needsAuth = true; // Creating issue is a write operation
    updateStatus('Creating issue...');
    screen.render();

    const octokit = await initOctokit();
    
    if (!state.token) {
      showMessage('A GitHub token is required to create issues!', 'error');
      return;
    }
    
    const { data: issue } = await octokit.rest.issues.create({
      owner: state.owner,
      repo: state.repo,
      title,
      body,
    });

    showMessage(`Issue #${issue.number} created successfully in ${state.owner}/${state.repo}!`, 'success');
    refreshIssues();
  } catch (error) {
    state.error = error.message;
    updateStatus(`Error: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

async function createComment(body) {
  try {
    if (!state.selectedIssue) return;
    
    state.loading = true;
    state.needsAuth = true; // Commenting is a write operation
    updateStatus(`Adding comment to issue #${state.selectedIssue.number}...`);
    screen.render();

    const octokit = await initOctokit();
    
    if (!state.token) {
      showMessage('A GitHub token is required to add comments!', 'error');
      return;
    }
    
    await octokit.rest.issues.createComment({
      owner: state.owner,
      repo: state.repo,
      issue_number: state.selectedIssue.number,
      body,
    });

    showMessage('Comment added successfully!', 'success');
    fetchIssueDetails(state.selectedIssue.number);
  } catch (error) {
    state.error = error.message;
    updateStatus(`Error: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

// Functions to update the interface
function updateIssuesList() {
  issuesList.setItems(
    state.issues.map((issue) => {
      let prefix = '#' + issue.number;
      if (issue.state === 'open') {
        prefix = '{green-fg}' + prefix + '{/green-fg}';
      } else {
        prefix = '{red-fg}' + prefix + '{/red-fg}';
      }
      return `${prefix} ${issue.title.substring(0, 40)}${issue.title.length > 40 ? '...' : ''}`;
    })
  );

  if (state.issues.length > 0) {
    issuesList.select(0);
    state.selectedIssue = state.issues[0];
  }

  screen.render();
}

function updateIssueDetails(issue, comments = []) {
  state.selectedIssue = issue;

  const stateColor = issue.state === 'open' ? '{green-fg}Open{/green-fg}' : '{red-fg}Closed{/red-fg}';
  
  let content = '';
  content += `{bold}#${issue.number}: ${issue.title}{/bold}\n\n`;
  content += `{bold}State:{/bold} ${stateColor}\n`;
  content += `{bold}Created by:{/bold} ${issue.user.login}\n`;
  content += `{bold}Created:{/bold} ${new Date(issue.created_at).toLocaleString()}\n`;
  
  if (issue.labels.length > 0) {
    content += `{bold}Labels:{/bold} ${issue.labels.map((l) => l.name).join(', ')}\n`;
  }
  
  content += `\n{bold}Description:{/bold}\n${issue.body || 'No description'}\n\n`;
  
  if (comments.length > 0) {
    content += `{bold}Comments (${comments.length}):{/bold}\n\n`;
    
    comments.forEach((comment) => {
      content += `{bold}${comment.user.login}{/bold} on ${new Date(comment.created_at).toLocaleString()}\n`;
      content += `${comment.body}\n\n`;
    });
  } else {
    content += '{bold}Comments:{/bold} No comments yet\n';
  }
  
  issueDetails.setContent(content);
  screen.render();
}

function updateStatus(message, type = 'info') {
  const colors = {
    info: '{white-fg}{blue-bg}',
    success: '{white-fg}{green-bg}',
    error: '{white-fg}{red-bg}',
  };

  statusBar.setContent(`${colors[type]} ${message} {/}`);
  screen.render();
}

function refreshIssues() {
  state.selectedIssue = null;
  issueDetails.setContent('Loading...');
  fetchIssues();
}

// Eventos e atalhos de teclado
issuesList.on('select', (item, index) => {
  const issue = state.issues[index];
  if (issue) {
    fetchIssueDetails(issue.number);
  }
});

screen.key(['escape', 'q', 'C-c'], () => {
  return process.exit(0);
});

screen.key('r', () => {
  refreshIssues();
});

screen.key('c', () => {
  promptComment();
});

// Inicializar
screen.title = 'LazyVim Issues CLI';
screen.key(['tab'], (ch, key) => {
  if (screen.focused.parent === issuesList.parent) {
    issueDetails.focus();
  } else {
    issuesList.focus();
  }
});

issuesList.focus();
fetchIssues();

// Habilitar o mouse
screen.enableMouse();

// Function to check API limits
async function checkApiLimits() {
  try {
    state.loading = true;
    updateStatus('Checking API rate limits...');
    screen.render();

    const octokit = await initOctokit(false);
    
    const { data } = await octokit.rest.rateLimit.get();
    
    // Calculate when the limit will be reset
    const resetDate = new Date(data.rate.reset * 1000);
    const now = new Date();
    const diffMinutes = Math.round((resetDate - now) / 60000);
    
    let message = '\n{bold}=== GitHub API Rate Limits Status ===\n{/bold}\n';
    
    if (state.token) {
      message += '{bold}Mode:{/bold} Authenticated\n';
    } else {
      message += '{bold}Mode:{/bold} Not authenticated\n';
      message += '{yellow-fg}Configure a token to increase the limit from 60 to 5000 req/hour{/yellow-fg}\n';
    }
    
    message += `\n{bold}Remaining requests:{/bold} ${data.rate.remaining} / ${data.rate.limit}\n`;
    message += `{bold}Next reset:{/bold} ${resetDate.toLocaleTimeString()} (in ~${diffMinutes} minutes)\n`;
    
    if (data.resources) {
      message += '\n{bold}Resource-specific limits:{/bold}\n';
      
      if (data.resources.core) {
        message += `Core: ${data.resources.core.remaining} / ${data.resources.core.limit}\n`;
      }
      
      if (data.resources.search) {
        message += `Search: ${data.resources.search.remaining} / ${data.resources.search.limit}\n`;
      }
    }
    
    message += '\n{bold}Tips:{/bold}\n';
    message += '• Unauthenticated users: 60 requests/hour\n';
    message += '• Authenticated users: 5,000 requests/hour\n';
    message += '• Search has a separate limit of 30 requests/minute\n';
    
    issueDetails.setContent(message);
    updateStatus('GitHub API rate limits checked');
  } catch (error) {
    state.error = error.message;
    updateStatus(`Error: ${error.message}`, 'error');
  } finally {
    state.loading = false;
    screen.render();
  }
}

module.exports = {
  start: (owner, repo) => {
    if (owner && repo) {
      state.owner = owner;
      state.repo = repo;
      updateTitle();
    }
    screen.render();
  },
};

// Se este arquivo for executado diretamente
if (require.main === module) {
  screen.render();
} 