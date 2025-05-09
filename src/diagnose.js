#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');
const { dumpSystemInfo, LOG_FILE, LOG_DIR } = require('./utils/logger');

// ANSI colors for output formatting
const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
};

// Create diagnostic report file
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const reportPath = path.join(LOG_DIR, `diagnostic-report-${timestamp}.txt`);
let reportContent = '';

// Helper to append to report
function appendToReport(text) {
  reportContent += text + '\n';
  console.log(text);
}

// Section header
function sectionHeader(title) {
  const line = '='.repeat(title.length + 4);
  appendToReport('\n' + line);
  appendToReport(`| ${title} |`);
  appendToReport(line + '\n');
}

// Run a command and get its output
function runCommand(command, errorMessage = 'Command failed') {
  try {
    const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
    return output.trim();
  } catch (error) {
    return `${errorMessage}: ${error.message}`;
  }
}

// Start diagnostic report
appendToReport(`ISSUES-NEOVIM DIAGNOSTIC REPORT`);
appendToReport(`Generated: ${new Date().toLocaleString()}`);
appendToReport(`=`.repeat(50));

// System information
sectionHeader('SYSTEM INFORMATION');
const sysInfo = dumpSystemInfo();
appendToReport(`Platform: ${sysInfo.platform}`);
appendToReport(`Architecture: ${sysInfo.arch}`);
appendToReport(`Node.js Version: ${sysInfo.nodeVersion}`);
appendToReport(`User Home: ${os.homedir()}`);
appendToReport(`GitHub Token: ${sysInfo.env.GITHUB_TOKEN}`);

// Node.js and NPM versions
sectionHeader('NODE.JS AND NPM');
appendToReport(`Node.js: ${runCommand('node --version', 'Node.js not found')}`);
appendToReport(`NPM: ${runCommand('npm --version', 'NPM not found')}`);

// Check issues-neovim installation
sectionHeader('ISSUES-NEOVIM INSTALLATION');
appendToReport(`CLI accessible: ${
  runCommand('which issues-neovim || echo "Not found"', 'CLI not found')
}`);

// Package details
try {
  const packageJsonPath = path.resolve(__dirname, '..', 'package.json');
  if (fs.existsSync(packageJsonPath)) {
    const packageJson = require(packageJsonPath);
    appendToReport(`Package version: ${packageJson.version}`);
    appendToReport(`Dependencies: ${Object.keys(packageJson.dependencies).length} installed`);
  } else {
    appendToReport('Package.json not found');
  }
} catch (error) {
  appendToReport(`Error reading package.json: ${error.message}`);
}

// Check npm global installation
sectionHeader('NPM GLOBAL INSTALLATION STATUS');
appendToReport(runCommand('npm list -g issues-neovim', 'Not installed globally'));

// Check GitHub API access
sectionHeader('GITHUB API ACCESS');
const githubApiCommand = 'curl -s -o /dev/null -w "%{http_code}" https://api.github.com';
const apiStatus = runCommand(githubApiCommand, 'Failed to check GitHub API');
appendToReport(`GitHub API Status: ${apiStatus === '200' ? 'Accessible (200)' : 'Issue (Status: ' + apiStatus + ')'}`);

// Check environment variables
sectionHeader('ENVIRONMENT VARIABLES');
appendToReport(`GITHUB_TOKEN set: ${process.env.GITHUB_TOKEN ? 'Yes' : 'No'}`);
appendToReport(`DEBUG set: ${process.env.DEBUG || 'No'}`);
appendToReport(`NODE_PATH: ${process.env.NODE_PATH || 'Not set'}`);

// Recent log entries (last 20 lines)
sectionHeader('RECENT LOGS');
if (fs.existsSync(LOG_FILE)) {
  const logContent = fs.readFileSync(LOG_FILE, 'utf-8')
    .split('\n')
    .filter(line => !!line)
    .slice(-20)
    .join('\n');
  appendToReport(logContent);
} else {
  appendToReport('No log file found at: ' + LOG_FILE);
}

// Check for Neovim
sectionHeader('NEOVIM INSTALLATION');
appendToReport(`Neovim: ${runCommand('nvim --version | head -n 1', 'Neovim not found')}`);

// Floating terminal plugin
sectionHeader('DEPENDENCIES CHECK');
appendToReport(`vim-floaterm: ${
  runCommand(`find ~/.local/share/nvim -name "*floaterm*" | grep -q . && echo "Found" || echo "Not found"`, 
  'vim-floaterm check failed')
}`);

// Save the report
fs.writeFileSync(reportPath, reportContent);
console.log(`\n${colors.green}Diagnostic report saved to:${colors.reset} ${reportPath}`);
console.log(`\n${colors.yellow}Please include this file when reporting issues.${colors.reset}`);