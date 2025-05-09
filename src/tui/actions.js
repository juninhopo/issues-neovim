const { updateTitle, updateStatus } = require('./ui');
const { fetchIssues, searchIssues } = require('./api');

// Refresh the issues list
function refreshIssues(state, ui) {
  // Update application title
  updateTitle(state, ui);
  
  // Show loading state
  state.loading = true;
  updateStatus(ui, 'Loading issues...', 'info');
  
  // Clear any previous errors
  state.error = null;
  
  // Reset page if needed
  if (state.page < 1) state.page = 1;
  
  // Fetch issues based on current state
  if (state.searchTerm) {
    searchIssues(state, ui);
  } else {
    fetchIssues(state, ui);
  }
}

// Navigate to the next page
function nextPage(state, ui) {
  if (state.loading) return;
  
  state.page++;
  refreshIssues(state, ui);
}

// Navigate to the previous page
function prevPage(state, ui) {
  if (state.loading || state.page <= 1) return;
  
  state.page--;
  refreshIssues(state, ui);
}

// Reset the view
function resetView(state, ui) {
  state.searchTerm = '';
  state.page = 1;
  state.selectedIssue = null;
  state.view = 'issues';
  
  refreshIssues(state, ui);
}

module.exports = {
  refreshIssues,
  nextPage,
  prevPage,
  resetView
}; 