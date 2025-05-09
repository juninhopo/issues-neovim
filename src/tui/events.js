// Register event handlers for the TUI
function registerEventHandlers(state, { screen, components }) {
  // Quit on q, or Control-C
  screen.key(['q', 'C-c'], () => process.exit(0));
  
  // Refresh on r
  screen.key('r', () => {
    require('./actions').refreshIssues(state, { screen, components });
  });
  
  // Issue selection handler
  components.issuesList.on('select', (item, idx) => {
    state.selectedIssue = state.issues[idx];
    require('./api').fetchIssueDetails(state, { screen, components }, state.selectedIssue.number);
  });
  
  // Comment on c
  screen.key('c', () => {
    if (state.selectedIssue) {
      require('./prompts').promptComment(state, { screen, components });
    }
  });
  
  // Focus handling
  components.issuesList.key(['tab'], () => {
    components.issueDetails.focus();
  });
  
  components.issueDetails.key(['tab'], () => {
    components.issuesList.focus();
  });
  
  // Set initial focus
  components.issuesList.focus();
}

module.exports = { registerEventHandlers }; 