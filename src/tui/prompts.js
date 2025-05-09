const blessed = require('blessed');
const { updateStatus } = require('./ui');

// Prompt for GitHub token
function promptGitHubToken(state) {
  return new Promise((resolve) => {
    const prompt = blessed.prompt({
      parent: state.screen,
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
      state.screen.render();
      resolve(value);
    });

    state.screen.render();
  });
}

// Prompt for search term
function promptSearch(state, ui) {
  const { screen } = ui;
  
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
    prompt.destroy();
    screen.render();
    
    if (value) {
      state.searchTerm = value;
      require('./api').searchIssues(state, ui);
    }
  });

  screen.render();
}

// Prompt for creating a new issue
function promptCreateIssue(state, ui) {
  const { screen } = ui;
  
  // First, prompt for title
  const titlePrompt = blessed.prompt({
    parent: screen,
    border: 'line',
    height: 'shrink',
    width: '70%',
    top: 'center',
    left: 'center',
    label: ' New Issue - Title ',
    keys: true,
    vi: true,
  });

  titlePrompt.input('Enter issue title:', '', (err, title) => {
    titlePrompt.destroy();
    screen.render();
    
    if (!title) return;
    
    // Then prompt for body
    const bodyEditor = blessed.textarea({
      parent: screen,
      border: 'line',
      width: '80%',
      height: '60%',
      top: 'center',
      left: 'center',
      label: ' New Issue - Description ',
      keys: true,
      vi: true,
      inputOnFocus: true,
      padding: {
        left: 1,
        right: 1
      }
    });
    
    // Help text
    const helpBox = blessed.box({
      parent: screen,
      border: 'line',
      width: '80%',
      height: 3,
      bottom: '10%',
      left: 'center',
      content: ' Press ESC to cancel, Ctrl+S to submit ',
      align: 'center',
      valign: 'middle',
      style: {
        fg: 'white',
        bg: 'blue'
      }
    });

    screen.saveFocus();
    bodyEditor.focus();
    screen.render();

    bodyEditor.key(['escape'], () => {
      bodyEditor.destroy();
      helpBox.destroy();
      screen.restoreFocus();
      screen.render();
    });

    bodyEditor.key(['C-s'], () => {
      const body = bodyEditor.getValue();
      bodyEditor.destroy();
      helpBox.destroy();
      screen.restoreFocus();
      screen.render();
      
      if (title) {
        require('./api').createIssue(state, ui, title, body);
      }
    });
  });

  screen.render();
}

// Prompt for commenting on an issue
function promptComment(state, ui) {
  if (!state.selectedIssue) {
    updateStatus(ui, 'No issue selected', 'error');
    return;
  }
  
  const { screen } = ui;
  
  // Create a text area for comment
  const commentEditor = blessed.textarea({
    parent: screen,
    border: 'line',
    width: '80%',
    height: '60%',
    top: 'center',
    left: 'center',
    label: ` Comment on Issue #${state.selectedIssue.number} `,
    keys: true,
    vi: true,
    inputOnFocus: true,
    padding: {
      left: 1,
      right: 1
    }
  });
  
  // Help text
  const helpBox = blessed.box({
    parent: screen,
    border: 'line',
    width: '80%',
    height: 3,
    bottom: '10%',
    left: 'center',
    content: ' Press ESC to cancel, Ctrl+S to submit ',
    align: 'center',
    valign: 'middle',
    style: {
      fg: 'white',
      bg: 'blue'
    }
  });

  screen.saveFocus();
  commentEditor.focus();
  screen.render();

  commentEditor.key(['escape'], () => {
    commentEditor.destroy();
    helpBox.destroy();
    screen.restoreFocus();
    screen.render();
  });

  commentEditor.key(['C-s'], () => {
    const body = commentEditor.getValue();
    commentEditor.destroy();
    helpBox.destroy();
    screen.restoreFocus();
    screen.render();
    
    if (body) {
      require('./api').createComment(state, ui, body);
    }
  });
}

module.exports = {
  promptGitHubToken,
  promptSearch,
  promptCreateIssue,
  promptComment
}; 