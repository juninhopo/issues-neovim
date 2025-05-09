const chalk = require('chalk');
const ora = require('ora');
const inquirer = require('inquirer');
const api = require('./api');

// Command to list issues
async function listIssues(owner, repo, options) {
  try {
    const spinner = ora('Fetching issues...').start();
    
    const state = options.closed ? 'closed' : 'open';
    
    try {
      const issues = await api.fetchIssues(owner, repo, {
        state,
        perPage: parseInt(options.limit)
      });
      
      spinner.stop();
      
      if (issues.length === 0) {
        console.log(chalk.yellow(`No ${state} issues found in ${owner}/${repo}.`));
        return;
      }
      
      console.log(chalk.bold(`\n${state === 'open' ? 'Open' : 'Closed'} issues from ${owner}/${repo}:\n`));
      
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
        console.log(chalk.cyan('GITHUB_TOKEN=your_token issues-neovim list'));
      } else {
        throw apiError;
      }
    }
  } catch (error) {
    console.error(chalk.red('Error fetching issues:'), error.message);
    process.exit(1);
  }
}

// Command to view issue details
async function viewIssue(owner, repo, number) {
  try {
    const spinner = ora('Fetching issue details...').start();
    
    try {
      const issue = await api.fetchIssue(owner, repo, number);
      const comments = await api.fetchComments(owner, repo, number);
      
      spinner.stop();
      
      console.log(chalk.bold.green(`\n#${issue.number}: ${issue.title}\n`));
      console.log(`${chalk.blue('Repository:')} ${owner}/${repo}`);
      console.log(`${chalk.blue('URL:')} ${issue.html_url}`);
      console.log(`${chalk.blue('State:')} ${issue.state === 'open' ? chalk.green('Open') : chalk.red('Closed')}`);
      console.log(`${chalk.blue('Created:')} ${new Date(issue.created_at).toLocaleString()} by ${chalk.cyan(issue.user.login)}`);
      console.log(`${chalk.blue('Updated:')} ${new Date(issue.updated_at).toLocaleString()}`);
      
      console.log(`\n${chalk.blue('Description:')}\n${issue.body || '(No description provided)'}`);
      
      if (comments.length > 0) {
        console.log(`\n${chalk.blue(`Comments (${comments.length}):`)} \n`);
        
        comments.forEach((comment, index) => {
          console.log(`${chalk.cyan(comment.user.login)} commented on ${new Date(comment.created_at).toLocaleString()}:`);
          console.log(`${comment.body}`);
          
          if (index < comments.length - 1) {
            console.log(`\n${'-'.repeat(50)}\n`);
          }
        });
      } else {
        console.log(`\n${chalk.blue('Comments:')} No comments yet`);
      }
      
    } catch (apiError) {
      spinner.stop();
      if (apiError.status === 404) {
        console.error(chalk.red(`Error: Issue #${number} not found in ${owner}/${repo}`));
      } else if (apiError.status === 403 && apiError.message.includes('API rate limit exceeded')) {
        console.error(chalk.red('Error: GitHub API rate limit exceeded.'));
        console.log(chalk.yellow('Tip: Authenticate with a token to increase rate limits.'));
      } else {
        throw apiError;
      }
    }
  } catch (error) {
    console.error(chalk.red('Error viewing issue:'), error.message);
    process.exit(1);
  }
}

// Command to create a new issue
async function createIssue(owner, repo) {
  try {
    // Interactive prompts for issue creation
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'title',
        message: 'Issue title:',
        validate: input => input.length > 0 ? true : 'Title is required'
      },
      {
        type: 'editor',
        name: 'body',
        message: 'Issue description (opens in your default text editor):',
      },
      {
        type: 'confirm',
        name: 'confirm',
        message: 'Create this issue?',
        default: true
      }
    ]);
    
    if (!answers.confirm) {
      console.log(chalk.yellow('Issue creation canceled.'));
      return;
    }
    
    const spinner = ora('Creating issue...').start();
    
    try {
      const issue = await api.createIssue(owner, repo, answers.title, answers.body);
      
      spinner.stop();
      
      console.log(chalk.green(`\nIssue #${issue.number} created successfully!`));
      console.log(`${chalk.blue('URL:')} ${issue.html_url}`);
    } catch (apiError) {
      spinner.stop();
      
      if (apiError.status === 403 && apiError.message.includes('API rate limit exceeded')) {
        console.error(chalk.red('Error: GitHub API rate limit exceeded.'));
      } else if (apiError.status === 401) {
        console.error(chalk.red('Error: Authentication failed. Please provide a valid GitHub token.'));
      } else {
        throw apiError;
      }
    }
  } catch (error) {
    console.error(chalk.red('Error creating issue:'), error.message);
    process.exit(1);
  }
}

// Command to comment on an issue
async function commentOnIssue(owner, repo, number) {
  try {
    // First check if the issue exists
    const spinner = ora('Checking issue...').start();
    
    try {
      await api.fetchIssue(owner, repo, number);
      
      spinner.stop();
      
      // Interactive prompt for comment
      const answers = await inquirer.prompt([
        {
          type: 'editor',
          name: 'body',
          message: 'Comment text (opens in your default text editor):',
          validate: input => input.length > 0 ? true : 'Comment text is required'
        },
        {
          type: 'confirm',
          name: 'confirm',
          message: 'Post this comment?',
          default: true
        }
      ]);
      
      if (!answers.confirm) {
        console.log(chalk.yellow('Comment posting canceled.'));
        return;
      }
      
      const commentSpinner = ora('Posting comment...').start();
      
      try {
        const comment = await api.createComment(owner, repo, number, answers.body);
        
        commentSpinner.stop();
        
        console.log(chalk.green('\nComment posted successfully!'));
        console.log(`${chalk.blue('URL:')} ${comment.html_url}`);
      } catch (commentError) {
        commentSpinner.stop();
        
        if (commentError.status === 403 && commentError.message.includes('API rate limit exceeded')) {
          console.error(chalk.red('Error: GitHub API rate limit exceeded.'));
        } else if (commentError.status === 401) {
          console.error(chalk.red('Error: Authentication failed. Please provide a valid GitHub token.'));
        } else {
          throw commentError;
        }
      }
    } catch (issueError) {
      spinner.stop();
      
      if (issueError.status === 404) {
        console.error(chalk.red(`Error: Issue #${number} not found in ${owner}/${repo}`));
      } else {
        throw issueError;
      }
    }
  } catch (error) {
    console.error(chalk.red('Error commenting on issue:'), error.message);
    process.exit(1);
  }
}

// Command to check rate limits
async function checkRateLimits() {
  try {
    const spinner = ora('Checking API rate limits...').start();
    
    try {
      const limits = await api.checkRateLimits();
      
      spinner.stop();
      
      const { limit, remaining, reset } = limits;
      const resetDate = new Date(reset * 1000).toLocaleString();
      
      console.log(chalk.bold('\nGitHub API Rate Limits:'));
      console.log(`${chalk.blue('Limit:')} ${limit} requests per hour`);
      console.log(`${chalk.blue('Remaining:')} ${remaining} requests`);
      console.log(`${chalk.blue('Reset Time:')} ${resetDate}`);
      
      // Show warning if running low
      if (remaining < limit * 0.1) {
        console.log(chalk.yellow('\nWarning: You are running low on API requests!'));
      } else {
        console.log(chalk.green('\nStatus: OK'));
      }
    } catch (apiError) {
      spinner.stop();
      throw apiError;
    }
  } catch (error) {
    console.error(chalk.red('Error checking rate limits:'), error.message);
    process.exit(1);
  }
}

module.exports = {
  listIssues,
  viewIssue,
  createIssue,
  commentOnIssue,
  checkRateLimits
}; 