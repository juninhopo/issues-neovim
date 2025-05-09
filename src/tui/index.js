#!/usr/bin/env node

const { initScreen } = require('./screen');
const { initState } = require('./state');
const { refreshIssues } = require('./actions');

// Main entry point for TUI
function start(owner, repo) {
  // Initialize state with repository information
  const state = initState();
  state.owner = owner || state.owner;
  state.repo = repo || state.repo;
  
  // Initialize the screen components
  const screen = initScreen(state);
  
  // Initial fetch of issues
  refreshIssues(state, screen);
  
  // Render the screen
  screen.render();
}

module.exports = { start }; 