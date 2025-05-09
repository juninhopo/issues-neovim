const blessed = require('blessed');
const contrib = require('blessed-contrib');
const { registerEventHandlers } = require('./events');

// Initialize the screen and UI components
function initScreen(state) {
  // Initialize the main screen
  const screen = blessed.screen({
    smartCSR: true,
    title: 'GitHub Issues',
    dockBorders: true,
    fullUnicode: true,
  });

  // Layout principal usando grid
  const grid = new contrib.grid({ rows: 12, cols: 12, screen: screen });

  // Interface components
  const components = {
    header: grid.set(0, 0, 1, 12, blessed.box, {
      content: ' {bold}GitHub Issues CLI{/bold} ',
      tags: true,
      style: {
        fg: 'white',
        bg: 'blue',
      },
    }),

    tabs: grid.set(1, 0, 1, 12, blessed.listbar, {
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
        'Open Issues TESTE': {
          keys: ['1'],
          callback: () => {
            state.issueState = 'open';
            state.selectedTab = 0;
            require('./actions').refreshIssues(state, { screen, components });
          },
        },
        'Closed Issues': {
          keys: ['2'],
          callback: () => {
            state.issueState = 'closed';
            state.selectedTab = 1;
            require('./actions').refreshIssues(state, { screen, components });
          },
        },
        'Search': {
          keys: ['3'],
          callback: () => require('./prompts').promptSearch(state, { screen, components }),
        },
        'Create Issue': {
          keys: ['4'],
          callback: () => require('./prompts').promptCreateIssue(state, { screen, components }),
        },
        'API Limits': {
          keys: ['5'],
          callback: () => require('./api').checkApiLimits(state, { screen, components }),
        },
        'Exit (q)': {
          keys: ['q'],
          callback: () => process.exit(0),
        },
      },
    }),

    issuesList: grid.set(2, 0, 8, 4, blessed.list, {
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
    }),

    issueDetails: grid.set(2, 4, 8, 8, blessed.box, {
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
    }),

    statusBar: grid.set(10, 0, 1, 12, blessed.text, {
      content: ' Loading...',
      tags: true,
      style: {
        fg: 'white',
        bg: 'blue',
      },
    }),

    helpBar: grid.set(11, 0, 1, 12, blessed.text, {
      content: ' {bold}↑/↓{/bold}: Navigate  {bold}Enter{/bold}: View Details  {bold}c{/bold}: Comment  {bold}r{/bold}: Refresh  {bold}5{/bold}: API Limits  {bold}q{/bold}: Exit',
      tags: true,
      style: {
        fg: 'white',
        bg: 'black',
      },
    }),
  };

  // Register event handlers
  registerEventHandlers(state, { screen, components });

  // Return screen and components
  return { screen, components };
}

module.exports = { initScreen }; 