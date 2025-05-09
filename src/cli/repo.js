const chalk = require('chalk');
const simpleGit = require('simple-git');

// Function to detect current repository
async function detectRepository() {
  const result = {
    detected: false,
    owner: 'juninhopo',
    repo: 'issues-neovim'
  };
  
  try {
    const git = simpleGit(process.cwd());
    
    // Check if we're in a git repository
    const isRepo = await git.checkIsRepo();
    if (!isRepo) {
      console.log(chalk.yellow('Warning: Not in a Git repository. Using default repository (juninhopo/issues-neovim).'));
      return result;
    }
    
    // Get remote URL
    const remotes = await git.getRemotes(true);
    if (!remotes || remotes.length === 0) {
      console.log(chalk.yellow('Warning: No remotes configured. Using default repository (juninhopo/issues-neovim).'));
      return result;
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
        result.owner = match[1];
        result.repo = match[2];
        result.detected = true;
        console.log(chalk.green(`Repository detected: ${result.owner}/${result.repo}`));
        return result;
      }
    }
    
    console.log(chalk.yellow(`Warning: Couldn't extract GitHub info from URL: ${url}`));
    console.log(chalk.yellow('Using default repository (juninhopo/issues-neovim).'));
    return result;
  } catch (error) {
    console.log(chalk.yellow(`Warning: Error detecting repository: ${error.message}`));
    console.log(chalk.yellow('Using default repository (juninhopo/issues-neovim).'));
    return result;
  }
}

module.exports = { detectRepository }; 