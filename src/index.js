#!/usr/bin/env node

const { program } = require('commander');
const { Octokit } = require('octokit');
const chalk = require('chalk');
const inquirer = require('inquirer');
const ora = require('ora');
const simpleGit = require('simple-git');
const path = require('path');
const fs = require('fs');

// Repository state
let OWNER = 'LazyVim';
let REPO = 'LazyVim';
let repoDetected = false;

// Function to detect current repository
async function detectRepository() {
  try {
    const git = simpleGit(process.cwd());
    
    // Check if we're in a git repository
    const isRepo = await git.checkIsRepo();
    if (!isRepo) {
      console.log(chalk.yellow('Warning: Not in a Git repository. Using default repository (LazyVim/LazyVim).'));
      return false;
    }
    
    // Get remote URL
    const remotes = await git.getRemotes(true);
    if (!remotes || remotes.length === 0) {
      console.log(chalk.yellow('Warning: No remotes configured. Using default repository (LazyVim/LazyVim).'));
      return false;
    }
    
    // Look for origin remote or the first available
    const remote = remotes.find(r => r.name === 'origin') || remotes[0];
    const url = remote.refs.fetch;
    
    // Extract owner and repo from GitHub URL
    // Supports formats https://github.com/owner/repo.git and git@github.com:owner/repo.git
    let match;
    if (url.includes('github.com')) {
      if (url.startsWith('https')) {
        match = url.match(/github\.com\/([^\/]+)\/([^\/\.]+)(\.git)?$/);
      } else {
        match = url.match(/github\.com:([^\/]+)\/([^\/\.]+)(\.git)?$/);
      }
      
      if (match && match.length >= 3) {
        OWNER = match[1];
        REPO = match[2];
        console.log(chalk.green(`Repository detected: ${OWNER}/${REPO}`));
        return true;
      }
    }
    
    console.log(chalk.yellow(`Warning: Couldn't extract GitHub info from URL: ${url}`));
    console.log(chalk.yellow('Using default repository (LazyVim/LazyVim).'));
    return false;
  } catch (error) {
    console.log(chalk.yellow(`Warning: Error detecting repository: ${error.message}`));
    console.log(chalk.yellow('Using default repository (LazyVim/LazyVim).'));
    return false;
  }
}

// CLI version and description configuration
program
  .name('issue-lazyvim')
  .description('CLI for managing GitHub issues')
  .version('1.0.0');

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

// Command to start the TUI
program
  .command('tui')
  .description('Start the TUI (Terminal User Interface)')
  .action(async () => {
    // Detect repository before starting TUI
    repoDetected = await detectRepository();
    // Load and start TUI module
    require('./tui').start(OWNER, REPO);
  });

// Command to list issues
program
  .command('list')
  .description('List repository issues')
  .option('-o, --open', 'Show only open issues', true)
  .option('-c, --closed', 'Show only closed issues')
  .option('-l, --limit <number>', 'Maximum number of issues to display', '10')
  .action(async (options) => {
    try {
      // Detect repository
      repoDetected = await detectRepository();
      
      const spinner = ora('Fetching issues...').start();
      
      // Listing issues doesn't require authentication for public repositories
      const octokit = await initOctokit(false);
      const state = options.closed ? 'closed' : 'open';
      
      try {
        const { data: issues } = await octokit.rest.issues.listForRepo({
          owner: OWNER,
          repo: REPO,
          state,
          per_page: parseInt(options.limit)
        });
        
        spinner.stop();
        
        if (issues.length === 0) {
          console.log(chalk.yellow(`No ${state} issues found in ${OWNER}/${REPO}.`));
          return;
        }
        
        console.log(chalk.bold(`\n${state === 'open' ? 'Open' : 'Closed'} issues from ${OWNER}/${REPO}:\n`));
        
        issues.forEach(issue => {
          console.log(
            `${chalk.green('#' + issue.number)} ${chalk.white(issue.title)}`
          );
          console.log(`  ${chalk.blue(issue.html_url)}`);
          console.log(`  ${chalk.gray('Created: ' + new Date(issue.created_at).toLocaleDateString())}`);
          console.log();
        });
      } catch (apiError) {
        spinner.stop();
        if (apiError.status === 403 && apiError.message.includes('API rate limit exceeded')) {
          console.error(chalk.red('Error: GitHub API rate limit exceeded.'));
          console.log(chalk.yellow('Tip: Authenticate with a token to increase rate limits.'));
          console.log(chalk.yellow('Run the command with a GitHub token:'));
          console.log(chalk.cyan('GITHUB_TOKEN=your_token issue-lazyvim list'));
        } else {
          throw apiError;
        }
      }
    } catch (error) {
      console.error(chalk.red('Error fetching issues:'), error.message);
      process.exit(1);
    }
  });

// Command to view issue details
program
  .command('view <number>')
  .description('View details of a specific issue')
  .action(async (number) => {
    try {
      // Detect repository
      repoDetected = await detectRepository();
      
      const spinner = ora('Fetching issue details...').start();
      
      // Viewing details doesn't require authentication for public repositories
      const octokit = await initOctokit(false);
      
      const { data: issue } = await octokit.rest.issues.get({
        owner: OWNER,
        repo: REPO,
        issue_number: parseInt(number)
      });
      
      spinner.stop();
      
      console.log(chalk.bold.green(`\n#${issue.number}: ${issue.title}\n`));
      console.log(`${chalk.blue('Repository:')} ${OWNER}/${REPO}`);
      console.log(`${chalk.blue('URL:')} ${issue.html_url}`);
      console.log(`${chalk.blue('State:')} ${issue.state === 'open' ? chalk.green('Open') : chalk.red('Closed')}`);
      console.log(`${chalk.blue('Created:')} ${new Date(issue.created_at).toLocaleString()}`);
      console.log(`${chalk.blue('Created by:')} ${issue.user.login}`);
      
      if (issue.labels.length > 0) {
        console.log(`${chalk.blue('Labels:')} ${issue.labels.map(label => label.name).join(', ')}`);
      }
      
      console.log(`\n${chalk.blue('Description:')}\n${issue.body || 'No description'}\n`);
      
    } catch (error) {
      console.error(chalk.red('Error fetching issue details:'), error.message);
      process.exit(1);
    }
  });

// Command to create a new issue
program
  .command('create')
  .description('Create a new issue in the repository')
  .action(async () => {
    try {
      // Detect repository
      repoDetected = await detectRepository();
      
      // Creating issues requires authentication
      const octokit = await initOctokit(true);
      
      const answers = await inquirer.prompt([
        {
          type: 'input',
          name: 'title',
          message: 'Issue title:',
          validate: input => input.length > 0 ? true : 'Title is required'
        },
        {
          type: 'editor',
          name: 'description',
          message: 'Issue description (an editor will open):',
        },
        {
          type: 'confirm',
          name: 'confirm',
          message: `Confirm creation of issue in ${OWNER}/${REPO}?`,
          default: true
        }
      ]);
      
      if (!answers.confirm) {
        console.log(chalk.yellow('Issue creation cancelled.'));
        return;
      }
      
      const spinner = ora('Creating issue...').start();
      
      const { data: newIssue } = await octokit.rest.issues.create({
        owner: OWNER,
        repo: REPO,
        title: answers.title,
        body: answers.description || ''
      });
      
      spinner.stop();
      
      console.log(chalk.green(`\nIssue #${newIssue.number} created successfully in ${OWNER}/${REPO}!`));
      console.log(`URL: ${chalk.blue(newIssue.html_url)}\n`);
      
    } catch (error) {
      console.error(chalk.red('Error creating issue:'), error.message);
      process.exit(1);
    }
  });

// Command to comment on an issue
program
  .command('comment <number>')
  .description('Add a comment to an issue')
  .action(async (number) => {
    try {
      // Detect repository
      repoDetected = await detectRepository();
      
      // Commenting requires authentication
      const octokit = await initOctokit(true);
      
      const answers = await inquirer.prompt([
        {
          type: 'editor',
          name: 'comment',
          message: 'Enter your comment (an editor will open):',
          validate: input => input.length > 0 ? true : 'Comment cannot be empty'
        },
        {
          type: 'confirm',
          name: 'confirm',
          message: `Confirm posting comment on issue #${number} in ${OWNER}/${REPO}?`,
          default: true
        }
      ]);
      
      if (!answers.confirm) {
        console.log(chalk.yellow('Comment posting cancelled.'));
        return;
      }
      
      const spinner = ora('Posting comment...').start();
      
      await octokit.rest.issues.createComment({
        owner: OWNER,
        repo: REPO,
        issue_number: parseInt(number),
        body: answers.comment
      });
      
      spinner.stop();
      
      console.log(chalk.green(`\nComment added successfully to issue #${number} in ${OWNER}/${REPO}!`));
      
    } catch (error) {
      console.error(chalk.red('Error adding comment:'), error.message);
      process.exit(1);
    }
  });

// Command to search issues
program
  .command('search <term>')
  .description('Search issues by term')
  .action(async (term) => {
    try {
      // Detect repository
      repoDetected = await detectRepository();
      
      const spinner = ora('Searching issues...').start();
      
      // Searching issues doesn't require authentication for public repositories
      const octokit = await initOctokit(false);
      
      const { data: results } = await octokit.rest.search.issuesAndPullRequests({
        q: `repo:${OWNER}/${REPO} ${term} in:title,body`,
      });
      
      spinner.stop();
      
      if (results.items.length === 0) {
        console.log(chalk.yellow(`No issues found with term "${term}" in ${OWNER}/${REPO}.`));
        return;
      }
      
      console.log(chalk.bold(`\nSearch results for "${term}" in ${OWNER}/${REPO} (${results.total_count} found):\n`));
      
      results.items.slice(0, 10).forEach(issue => {
        console.log(
          `${chalk.green('#' + issue.number)} ${chalk.white(issue.title)}`
        );
        console.log(`  ${chalk.blue(issue.html_url)}`);
        console.log(`  ${chalk.gray('State: ' + (issue.state === 'open' ? 'Open' : 'Closed'))}`);
        console.log();
      });
      
      if (results.total_count > 10) {
        console.log(chalk.yellow(`...and ${results.total_count - 10} more results not shown.`));
      }
      
    } catch (error) {
      console.error(chalk.red('Error searching issues:'), error.message);
      process.exit(1);
    }
  });

// Define command aliases
program
  .command('listar', { hidden: true })
  .description('Alias for list command')
  .option('-a, --abertas', 'Alias for --open', true)
  .option('-f, --fechadas', 'Alias for --closed')
  .option('-l, --limite <number>', 'Alias for --limit', '10')
  .action(async (options) => {
    // Map the Portuguese options to English options
    const englishOptions = {
      open: options.abertas,
      closed: options.fechadas,
      limit: options.limite
    };
    // Call the original list command
    await program.commands.find(cmd => cmd.name() === 'list').action(englishOptions);
  });

program
  .command('ver', { hidden: true })
  .description('Alias for view command')
  .action((number) => {
    program.commands.find(cmd => cmd.name() === 'view').action(number);
  });

program
  .command('criar', { hidden: true })
  .description('Alias for create command')
  .action(() => {
    program.commands.find(cmd => cmd.name() === 'create').action();
  });

program
  .command('comentar', { hidden: true })
  .description('Alias for comment command')
  .action((number) => {
    program.commands.find(cmd => cmd.name() === 'comment').action(number);
  });

program
  .command('buscar', { hidden: true })
  .description('Alias for search command')
  .action((term) => {
    program.commands.find(cmd => cmd.name() === 'search').action(term);
  });

// Parse command line arguments
program.parse(process.argv);

// If no command is provided, start the TUI by default
if (!process.argv.slice(2).length) {
  // Detect repository before starting TUI
  detectRepository().then((detected) => {
    repoDetected = detected;
    require('./tui').start(OWNER, REPO);
  });
} 