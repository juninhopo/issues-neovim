// Application configuration

const path = require('path');
const os = require('os');
const fs = require('fs');

// Default configuration
const defaultConfig = {
  // Default repository
  defaultOwner: 'LazyVim',
  defaultRepo: 'LazyVim',
  
  // API settings
  perPage: 30,
  requestRetries: 3,
  requestRetryDelay: 1000,
  
  // UI preferences
  theme: {
    primary: 'blue',
    success: 'green',
    error: 'red',
    warning: 'yellow',
    info: 'cyan'
  },
  
  // Cache settings
  cacheEnabled: true,
  cacheDuration: 5 * 60 * 1000, // 5 minutes in milliseconds
  
  // File paths
  configPath: path.join(os.homedir(), '.config', 'issues-neovim', 'config.json'),
  cachePath: path.join(os.homedir(), '.cache', 'issues-neovim')
};

// Try to load user configuration
function loadConfig() {
  try {
    // Create config directory if it doesn't exist
    const configDir = path.dirname(defaultConfig.configPath);
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }
    
    // Check if config file exists
    if (fs.existsSync(defaultConfig.configPath)) {
      const userConfig = JSON.parse(fs.readFileSync(defaultConfig.configPath, 'utf8'));
      return { ...defaultConfig, ...userConfig };
    }
    
    // Create default config if it doesn't exist
    fs.writeFileSync(defaultConfig.configPath, JSON.stringify(defaultConfig, null, 2));
    return defaultConfig;
  } catch (error) {
    console.error(`Error loading configuration: ${error.message}`);
    return defaultConfig;
  }
}

// Save configuration to file
function saveConfig(config) {
  try {
    const configDir = path.dirname(defaultConfig.configPath);
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }
    
    fs.writeFileSync(defaultConfig.configPath, JSON.stringify(config, null, 2));
    return true;
  } catch (error) {
    console.error(`Error saving configuration: ${error.message}`);
    return false;
  }
}

// Ensure cache directory exists
function ensureCacheDir() {
  try {
    if (!fs.existsSync(defaultConfig.cachePath)) {
      fs.mkdirSync(defaultConfig.cachePath, { recursive: true });
    }
    return true;
  } catch (error) {
    console.error(`Error creating cache directory: ${error.message}`);
    return false;
  }
}

module.exports = {
  defaultConfig,
  loadConfig,
  saveConfig,
  ensureCacheDir
}; 