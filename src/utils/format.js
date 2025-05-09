// Utility functions for text formatting

/**
 * Format a date string to a human-readable format
 * @param {string} dateString - ISO date string
 * @returns {string} Formatted date string
 */
function formatDate(dateString) {
  return new Date(dateString).toLocaleString();
}

/**
 * Truncate text to specified length and add ellipsis if needed
 * @param {string} text - Text to truncate
 * @param {number} length - Maximum length
 * @returns {string} Truncated text
 */
function truncate(text, length = 80) {
  if (!text) return '';
  if (text.length <= length) return text;
  return text.substring(0, length - 3) + '...';
}

/**
 * Adds line wrapping to long text
 * @param {string} text - Text to wrap
 * @param {number} width - Maximum line width
 * @returns {string} Wrapped text
 */
function wrapText(text, width = 80) {
  if (!text) return '';
  
  const words = text.split(' ');
  let result = '';
  let line = '';
  
  for (const word of words) {
    if ((line + word).length > width) {
      result += line.trim() + '\n';
      line = word + ' ';
    } else {
      line += word + ' ';
    }
  }
  
  return result + line.trim();
}

/**
 * Formats labels for display
 * @param {Array} labels - Array of label objects
 * @returns {string} Formatted labels string
 */
function formatLabels(labels) {
  if (!labels || labels.length === 0) return '';
  
  return labels.map(label => label.name).join(', ');
}

/**
 * Create a horizontal separator
 * @param {number} length - Length of separator
 * @param {string} char - Character to use
 * @returns {string} Separator string
 */
function separator(length = 50, char = '-') {
  return char.repeat(length);
}

module.exports = {
  formatDate,
  truncate,
  wrapText,
  formatLabels,
  separator
}; 