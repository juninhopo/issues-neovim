#!/usr/bin/env node

const { program } = require('commander');
const { detectRepository } = require('./repo');
const commands = require('./commands');

// Repository state
let OWNER = 'juninhopo';
let REPO = 'issues-neovim';
let repoDetected = false;

// CLI version and description configuration
program
  .name('issues-neovim')
  .description('CLI for managing GitHub issues')
  .version('1.0.0');

// Command to start the TUI
program
  .command('tui')
  .description('Start the TUI (Terminal User Interface)')
  .action(async () => {
    // Detect repository before starting TUI
    const result = await detectRepository();
    if (result.detected) {
      OWNER = result.owner;
      REPO = result.repo;
    }
    // Load and start TUI module
    require('../tui').start(OWNER, REPO);
  });

// Command to list issues
program
  .command('list')
  .description('List repository issues')
  .option('-o, --open', 'Show only open issues', true)
  .option('-c, --closed', 'Show only closed issues')
  .option('-l, --limit <number>', 'Maximum number of issues to display', '10')
  .action(async (options) => {
    // Detect repository
    const result = await detectRepository();
    if (result.detected) {
      OWNER = result.owner;
      REPO = result.repo;
    }
    
    await commands.listIssues(OWNER, REPO, options);
  });

// Command to view issue details
program
  .command('view <number>')
  .description('View details of a specific issue')
  .action(async (number) => {
    // Detect repository
    const result = await detectRepository();
    if (result.detected) {
      OWNER = result.owner;
      REPO = result.repo;
    }
    
    await commands.viewIssue(OWNER, REPO, number);
  });

// Command to create a new issue
program
  .command('create')
  .description('Create a new issue interactively')
  .action(async () => {
    // Detect repository
    const result = await detectRepository();
    if (result.detected) {
      OWNER = result.owner;
      REPO = result.repo;
    }
    
    await commands.createIssue(OWNER, REPO);
  });

// Command to comment on an issue
program
  .command('comment <number>')
  .description('Add a comment to an issue')
  .action(async (number) => {
    // Detect repository
    const result = await detectRepository();
    if (result.detected) {
      OWNER = result.owner;
      REPO = result.repo;
    }
    
    await commands.commentOnIssue(OWNER, REPO, number);
  });

// Command to check API rate limits
program
  .command('limits')
  .description('Check GitHub API rate limits')
  .action(async () => {
    await commands.checkRateLimits();
  });

// Parse command line arguments
program.parse(process.argv); 