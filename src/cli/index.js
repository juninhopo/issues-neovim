#!/usr/bin/env node

const { program } = require('commander');
const { detectRepository } = require('./repo');
const commands = require('./commands');
const { createLogger, dumpSystemInfo } = require('../utils/logger');
const path = require('path');

// Create loggers
const logger = createLogger('cli');

// Repository state
let OWNER = 'juninhopo';
let REPO = 'issues-neovim';
let repoDetected = false;

// Global error handler
process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception', error);
  console.error('\n\x1b[31mAn unexpected error occurred:\x1b[0m', error.message);
  console.error('\nPlease report this issue with the following information:');
  console.error(`- Error message: ${error.message}`);
  console.error(`- Full error logs available at: ${require('../utils/logger').LOG_FILE}`);
  console.error('\nTo enable verbose debugging, run:');
  console.error('   DEBUG=issues-neovim:* issues-neovim <command>');
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled rejection', { reason, promise });
  console.error('\n\x1b[31mAn unhandled promise rejection occurred:\x1b[0m', reason);
  console.error('\nPlease report this issue with the log file mentioned above.');
  process.exit(1);
});

// CLI version and description configuration
program
  .name('issues-neovim')
  .description('CLI for managing GitHub issues')
  .version('1.0.0');

// Capture system info for diagnostics
program
  .command('debug')
  .description('Dump system information for debugging')
  .action(() => {
    console.log('Dumping system diagnostic information...');
    const info = dumpSystemInfo();
    console.log(JSON.stringify(info, null, 2));
    console.log(`\nComplete logs are saved in: ${require('../utils/logger').LOG_FILE}`);
    console.log('Please include this information when reporting issues.');
  });

// Full diagnostic report
program
  .command('diagnose')
  .description('Generate a complete diagnostic report for troubleshooting')
  .action(() => {
    try {
      logger.info('Running diagnostic report');
      // Run the diagnose script
      require('../diagnose');
    } catch (err) {
      logger.error('Failed to run diagnostics', err);
      console.error(`\x1b[31mError running diagnostics: ${err.message}\x1b[0m`);
      process.exit(1);
    }
  });

// Command to start the TUI
program
  .command('tui')
  .description('Start the TUI (Terminal User Interface)')
  .action(async () => {
    try {
      logger.info('Starting TUI');
      // Detect repository before starting TUI
      const result = await detectRepository();
      if (result.detected) {
        OWNER = result.owner;
        REPO = result.repo;
        logger.info(`Repository detected: ${OWNER}/${REPO}`);
      } else {
        logger.warn(`Using default repository: ${OWNER}/${REPO}`);
      }
      // Load and start TUI module
      require('../tui').start(OWNER, REPO);
    } catch (err) {
      logger.error('Failed to start TUI', err);
      console.error(`\x1b[31mError starting TUI: ${err.message}\x1b[0m`);
      console.error(`Check logs at: ${require('../utils/logger').LOG_FILE}`);
      process.exit(1);
    }
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
      logger.info('Listing issues', options);
      // Detect repository
      const result = await detectRepository();
      if (result.detected) {
        OWNER = result.owner;
        REPO = result.repo;
      }
      
      await commands.listIssues(OWNER, REPO, options);
    } catch (err) {
      logger.error('Failed to list issues', err);
      console.error(`\x1b[31mError listing issues: ${err.message}\x1b[0m`);
      process.exit(1);
    }
  });

// Command to view issue details
program
  .command('view <number>')
  .description('View details of a specific issue')
  .action(async (number) => {
    try {
      logger.info(`Viewing issue #${number}`);
      // Detect repository
      const result = await detectRepository();
      if (result.detected) {
        OWNER = result.owner;
        REPO = result.repo;
      }
      
      await commands.viewIssue(OWNER, REPO, number);
    } catch (err) {
      logger.error(`Failed to view issue #${number}`, err);
      console.error(`\x1b[31mError viewing issue: ${err.message}\x1b[0m`);
      process.exit(1);
    }
  });

// Command to create a new issue
program
  .command('create')
  .description('Create a new issue interactively')
  .action(async () => {
    try {
      logger.info('Creating new issue');
      // Detect repository
      const result = await detectRepository();
      if (result.detected) {
        OWNER = result.owner;
        REPO = result.repo;
      }
      
      await commands.createIssue(OWNER, REPO);
    } catch (err) {
      logger.error('Failed to create issue', err);
      console.error(`\x1b[31mError creating issue: ${err.message}\x1b[0m`);
      process.exit(1);
    }
  });

// Command to comment on an issue
program
  .command('comment <number>')
  .description('Add a comment to an issue')
  .action(async (number) => {
    try {
      logger.info(`Commenting on issue #${number}`);
      // Detect repository
      const result = await detectRepository();
      if (result.detected) {
        OWNER = result.owner;
        REPO = result.repo;
      }
      
      await commands.commentOnIssue(OWNER, REPO, number);
    } catch (err) {
      logger.error(`Failed to comment on issue #${number}`, err);
      console.error(`\x1b[31mError commenting on issue: ${err.message}\x1b[0m`);
      process.exit(1);
    }
  });

// Command to check API rate limits
program
  .command('limits')
  .description('Check GitHub API rate limits')
  .action(async () => {
    try {
      logger.info('Checking rate limits');
      await commands.checkRateLimits();
    } catch (err) {
      logger.error('Failed to check rate limits', err);
      console.error(`\x1b[31mError checking rate limits: ${err.message}\x1b[0m`);
      process.exit(1);
    }
  });

// Parse command line arguments
logger.info('Starting CLI', { args: process.argv.slice(2) });
program.parse(process.argv);