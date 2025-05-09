const fs = require('fs');
const path = require('path');
const debug = require('debug');
const os = require('os');

// Set up debug namespace
const DEBUG_NAMESPACE = 'issues-neovim';
const debugLog = debug(DEBUG_NAMESPACE);

// Define log levels
const LOG_LEVELS = {
  ERROR: 'error',
  WARN: 'warn',
  INFO: 'info',
  DEBUG: 'debug',
  TRACE: 'trace'
};

// Ensure log directory exists
const LOG_DIR = path.join(os.homedir(), '.issues-neovim');
if (!fs.existsSync(LOG_DIR)) {
  try {
    fs.mkdirSync(LOG_DIR, { recursive: true });
  } catch (err) {
    console.error(`Failed to create log directory: ${err.message}`);
  }
}

const LOG_FILE = path.join(LOG_DIR, 'debug.log');

// Create logger class
class Logger {
  constructor(module) {
    this.module = module;
    this.debugger = debug(`${DEBUG_NAMESPACE}:${module}`);
  }

  // Format log message with timestamp and module
  formatMessage(level, message, data = null) {
    const timestamp = new Date().toISOString();
    let formatted = `[${timestamp}] [${level.toUpperCase()}] [${this.module}] ${message}`;
    
    if (data) {
      if (typeof data === 'object') {
        try {
          formatted += `\n${JSON.stringify(data, null, 2)}`;
        } catch (e) {
          formatted += `\n[Object serialization failed: ${e.message}]`;
        }
      } else {
        formatted += `\n${data}`;
      }
    }
    
    return formatted;
  }

  // Write to file and console
  log(level, message, data = null) {
    const formattedMessage = this.formatMessage(level, message, data);
    
    // Write to debug console if enabled
    this.debugger(formattedMessage);
    
    // Always write to log file
    try {
      fs.appendFileSync(LOG_FILE, formattedMessage + '\n');
    } catch (err) {
      console.error(`Failed to write to log file: ${err.message}`);
    }
    
    // Also write to console for error and warn levels
    if (level === LOG_LEVELS.ERROR) {
      console.error(formattedMessage);
    } else if (level === LOG_LEVELS.WARN) {
      console.warn(formattedMessage);
    }
  }

  error(message, data = null) {
    this.log(LOG_LEVELS.ERROR, message, data);
  }

  warn(message, data = null) {
    this.log(LOG_LEVELS.WARN, message, data);
  }

  info(message, data = null) {
    this.log(LOG_LEVELS.INFO, message, data);
  }

  debug(message, data = null) {
    this.log(LOG_LEVELS.DEBUG, message, data);
  }

  trace(message, data = null) {
    this.log(LOG_LEVELS.TRACE, message, data);
  }

  // Capture and log errors
  captureError(error, context = {}) {
    const errorData = {
      message: error.message,
      stack: error.stack,
      ...context
    };
    
    this.error(`Error captured: ${error.message}`, errorData);
    return error; // Return for chaining
  }
}

// Export a helper to create loggers for different modules
function createLogger(module) {
  return new Logger(module || 'general');
}

// Export utility to dump system information for diagnostics
function dumpSystemInfo() {
  const logger = createLogger('system');
  
  const sysInfo = {
    platform: process.platform,
    nodeVersion: process.version,
    arch: process.arch,
    env: {
      GITHUB_TOKEN: process.env.GITHUB_TOKEN ? 'Set' : 'Not set',
      HOME: process.env.HOME,
      DEBUG: process.env.DEBUG
    },
    timestamp: new Date().toISOString()
  };
  
  logger.info('System information dump', sysInfo);
  return sysInfo;
}

module.exports = {
  createLogger,
  dumpSystemInfo,
  LOG_FILE,
  LOG_DIR,
  LOG_LEVELS
}; 