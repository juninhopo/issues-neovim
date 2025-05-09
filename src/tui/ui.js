// Update the interface based on app state

// Update the application title
function updateTitle(state, ui) {
  ui.screen.title = `GitHub Issues - ${state.owner}/${state.repo}`;
}

// Update the issues list
function updateIssuesList(state, ui) {
  const { components } = ui;
  
  // Clear the list
  components.issuesList.clearItems();
  
  // Update issues list
  if (state.issues.length === 0) {
    components.issuesList.pushItem('No issues found');
  } else {
    state.issues.forEach(issue => {
      const issueTitle = `#${issue.number} ${issue.title}`;
      components.issuesList.pushItem(issueTitle);
    });
  }
  
  // Update title for tab
  components.issuesList.setLabel(` Issues (${state.issues.length}) `);
  
  // Render changes
  ui.screen.render();
}

// Update the issue details view
function updateIssueDetails(state, ui, issue, comments = []) {
  const { components } = ui;
  
  if (!issue) {
    components.issueDetails.setContent('Select an issue to view details');
    ui.screen.render();
    return;
  }
  
  const createdAt = new Date(issue.created_at).toLocaleString();
  const updatedAt = new Date(issue.updated_at).toLocaleString();
  
  let content = `{bold}#${issue.number}: ${issue.title}{/bold}\n\n`;
  content += `{bold}State:{/bold} ${issue.state === 'open' ? '{green}Open{/green}' : '{red}Closed{/red}'}\n`;
  content += `{bold}Created:{/bold} ${createdAt} by {cyan}${issue.user.login}{/cyan}\n`;
  content += `{bold}Updated:{/bold} ${updatedAt}\n\n`;
  content += `{bold}Description:{/bold}\n${issue.body || '(No description)'}\n\n`;
  
  if (comments.length > 0) {
    content += `{bold}Comments (${comments.length}):{/bold}\n\n`;
    
    comments.forEach(comment => {
      const commentDate = new Date(comment.created_at).toLocaleString();
      content += `{cyan}${comment.user.login}{/cyan} commented on ${commentDate}:\n`;
      content += `${comment.body}\n${'-'.repeat(50)}\n\n`;
    });
  } else {
    content += '{bold}No comments{/bold}';
  }
  
  components.issueDetails.setContent(content);
  components.issueDetails.setLabel(` Issue #${issue.number} `);
  ui.screen.render();
}

// Update the status bar
function updateStatus(ui, message, type = 'info') {
  const { components } = ui;
  const statusColors = {
    info: 'blue',
    success: 'green',
    error: 'red',
    warning: 'yellow'
  };
  
  const color = statusColors[type] || statusColors.info;
  components.statusBar.style.bg = color;
  components.statusBar.setContent(` ${message} `);
  ui.screen.render();
}

// Show a message box
function showMessage(ui, message, type = 'info') {
  const colors = {
    info: 'blue',
    success: 'green',
    error: 'red',
    warning: 'yellow'
  };
  
  const box = blessed.box({
    top: 'center',
    left: 'center',
    width: '50%',
    height: 'shrink',
    content: message,
    tags: true,
    border: {
      type: 'line'
    },
    style: {
      fg: 'white',
      bg: colors[type] || colors.info,
      border: {
        fg: 'white'
      }
    }
  });
  
  ui.screen.append(box);
  ui.screen.render();
  
  // Close after 3 seconds
  setTimeout(() => {
    box.destroy();
    ui.screen.render();
  }, 3000);
}

module.exports = {
  updateTitle,
  updateIssuesList,
  updateIssueDetails,
  updateStatus,
  showMessage
}; 