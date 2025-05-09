const chalk = require('chalk');
const simpleGit = require('simple-git');
const { createLogger } = require('../utils/logger');

// Create logger for repository detection
const logger = createLogger('repo');

// Function to detect current repository
async function detectRepository() {
  const result = {
    detected: false,
    owner: 'juninhopo',
    repo: 'issues-neovim'
  };
  
  try {
    logger.info('Attempting to detect repository from current directory');
    const git = simpleGit(process.cwd());
    
    // Check if we're in a git repository
    const isRepo = await git.checkIsRepo();
    if (!isRepo) {
      logger.warn('Not in a Git repository');
      console.log(chalk.yellow('Warning: Not in a Git repository. Using default repository (juninhopo/issues-neovim).'));
      return result;
    }
    
    // Get remote URL
    logger.info('Getting Git remotes');
    const remotes = await git.getRemotes(true);
    if (!remotes || remotes.length === 0) {
      logger.warn('No Git remotes configured');
      console.log(chalk.yellow('Warning: No remotes configured. Using default repository (juninhopo/issues-neovim).'));
      return result;
    }
    
    // Look for origin remote or the first available
    const remote = remotes.find(r => r.name === 'origin') || remotes[0];
    const url = remote.refs.fetch;
    logger.info(`Found remote: ${remote.name}, URL: ${url}`);
    
    // Extract owner and repo from GitHub URL
    // Supports formats https://github.com/owner/repo.git and git@github.com:owner/repo.git
    let match;
    if (url.includes('github.com')) {
      logger.debug('URL appears to be from GitHub, attempting to parse');
      
      if (url.startsWith('https')) {
        match = url.match(/github\.com\/([^\/]+)\/([^\/\.]+)(\.git)?$/);
        logger.debug('Parsing as HTTPS URL');
      } else {
        match = url.match(/github\.com:([^\/]+)\/([^\/\.]+)(\.git)?$/);
        logger.debug('Parsing as SSH URL');
      }
      
      if (match && match.length >= 3) {
        result.owner = match[1];
        result.repo = match[2];
        result.detected = true;
        logger.info(`Successfully detected repository: ${result.owner}/${result.repo}`);
        console.log(chalk.green(`Repository detected: ${result.owner}/${result.repo}`));
        return result;
      } else {
        logger.warn(`Failed to parse GitHub URL format: ${url}`);
      }
    } else {
      logger.warn(`Remote URL doesn't appear to be from GitHub: ${url}`);
    }
    
    logger.warn(`Couldn't extract GitHub info from URL: ${url}`);
    console.log(chalk.yellow(`Warning: Couldn't extract GitHub info from URL: ${url}`));
    console.log(chalk.yellow('Using default repository (juninhopo/issues-neovim).'));
    return result;
  } catch (error) {
    logger.error('Error during repository detection', {
      error: error.message,
      stack: error.stack
    });
    console.log(chalk.yellow(`Warning: Error detecting repository: ${error.message}`));
    console.log(chalk.yellow('Using default repository (juninhopo/issues-neovim).'));
    return result;
  }
}

module.exports = { detectRepository }; 