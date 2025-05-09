// Global application state management
function initState() {
  return {
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
}

module.exports = { initState }; 