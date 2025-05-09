#!/usr/bin/env node

// Main entry point for the application
// This file delegates to the CLI module

// Handle simple version command directly for better health checks
if (process.argv.includes('--version')) {
  const packageJson = require('../package.json');
  console.log(packageJson.version);
  process.exit(0);
}

require('./cli');