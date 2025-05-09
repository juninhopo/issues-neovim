#!/usr/bin/env node

const { Octokit } = require('octokit');
const chalk = require('chalk');

async function checkRateLimit() {
  try {
    console.log(chalk.blue('Checking GitHub API rate limits...'));
    
    // Try to use token if it exists
    const token = process.env.GITHUB_TOKEN;
    const octokit = new Octokit({ 
      auth: token || undefined 
    });
    
    // Get rate limit information
    const { data } = await octokit.rest.rateLimit.get();
    
    console.log('\n' + chalk.green('=== GitHub API Rate Limits Status ==='));
    
    if (token) {
      console.log(chalk.blue('Mode: Authenticated'));
      console.log(chalk.yellow('Rate limit for authenticated users: 5000 requests per hour'));
    } else {
      console.log(chalk.blue('Mode: Not authenticated'));
      console.log(chalk.yellow('Rate limit for unauthenticated IPs: 60 requests per hour'));
      console.log(chalk.yellow('Configure a token to increase this limit:'));
      console.log(chalk.cyan('export GITHUB_TOKEN=your_token'));
    }
    
    // Display information
    console.log('\n' + chalk.cyan('Current limits:'));
    console.log(`Remaining requests: ${chalk.bold(data.rate.remaining)} / ${data.rate.limit}`);
    
    // Calculate when the limit will be reset
    const resetDate = new Date(data.rate.reset * 1000);
    const now = new Date();
    const diffMinutes = Math.round((resetDate - now) / 60000);
    
    console.log(`Next reset: ${chalk.bold(resetDate.toLocaleTimeString())} (in approximately ${diffMinutes} minutes)`);
    
    // Display information about other limits, if available
    if (data.resources) {
      console.log('\n' + chalk.cyan('Resource-specific limits:'));
      
      if (data.resources.core) {
        console.log(`Core: ${data.resources.core.remaining} / ${data.resources.core.limit}`);
      }
      
      if (data.resources.search) {
        console.log(`Search: ${data.resources.search.remaining} / ${data.resources.search.limit}`);
      }
      
      if (data.resources.graphql) {
        console.log(`GraphQL: ${data.resources.graphql.remaining} / ${data.resources.graphql.limit}`);
      }
    }
    
    console.log('\n' + chalk.green('====================================='));
    
    // Tips for handling limits
    if (data.rate.remaining < 10) {
      console.log(chalk.red('Warning! You have few remaining requests.'));
      console.log(chalk.yellow('Tips for handling rate limits:'));
      console.log('1. Authenticate with a token to increase the limit');
      console.log('2. Wait until the limit is reset');
      console.log('3. Reduce the number of unnecessary queries');
    }
    
  } catch (error) {
    console.error(chalk.red('Error checking limits:'), error.message);
  }
}

// Execute the function
checkRateLimit();

module.exports = {
  checkRateLimit
}; 