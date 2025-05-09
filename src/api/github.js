const { Octokit } = require('octokit');
const config = require('../config');

// Cache for API responses
const cache = new Map();

/**
 * Initialize GitHub API client
 * @param {string} token - GitHub API token
 * @returns {Object} Octokit instance
 */
function createClient(token) {
  return new Octokit({
    auth: token,
    request: {
      retries: config.defaultConfig.requestRetries,
      retryAfter: config.defaultConfig.requestRetryDelay / 1000
    }
  });
}

/**
 * Get cached response or fetch from API
 * @param {string} cacheKey - Cache key
 * @param {Function} fetchFn - Function to fetch data if not cached
 * @returns {Promise<any>} Cached or fresh data
 */
async function getCachedOrFetch(cacheKey, fetchFn) {
  const appConfig = config.loadConfig();
  
  // Return from cache if enabled and valid
  if (appConfig.cacheEnabled && cache.has(cacheKey)) {
    const { data, timestamp } = cache.get(cacheKey);
    const isValid = Date.now() - timestamp < appConfig.cacheDuration;
    
    if (isValid) {
      return data;
    }
  }
  
  // Fetch fresh data
  const data = await fetchFn();
  
  // Cache the result if caching is enabled
  if (appConfig.cacheEnabled) {
    cache.set(cacheKey, {
      data,
      timestamp: Date.now()
    });
  }
  
  return data;
}

/**
 * Clear all cached API responses
 */
function clearCache() {
  cache.clear();
}

/**
 * API Methods
 */
const api = {
  /**
   * List issues for a repository
   * @param {Object} params - Request parameters
   * @returns {Promise<Array>} List of issues
   */
  async listIssues({ token, owner, repo, state = 'open', perPage = 30, page = 1 }) {
    const client = createClient(token);
    const cacheKey = `issues:${owner}:${repo}:${state}:${page}:${perPage}`;
    
    return getCachedOrFetch(cacheKey, async () => {
      const { data } = await client.rest.issues.listForRepo({
        owner,
        repo,
        state,
        per_page: perPage,
        page
      });
      
      return data;
    });
  },
  
  /**
   * Get a single issue by number
   * @param {Object} params - Request parameters
   * @returns {Promise<Object>} Issue data
   */
  async getIssue({ token, owner, repo, issueNumber }) {
    const client = createClient(token);
    const cacheKey = `issue:${owner}:${repo}:${issueNumber}`;
    
    return getCachedOrFetch(cacheKey, async () => {
      const { data } = await client.rest.issues.get({
        owner,
        repo,
        issue_number: parseInt(issueNumber)
      });
      
      return data;
    });
  },
  
  /**
   * Get comments for an issue
   * @param {Object} params - Request parameters
   * @returns {Promise<Array>} List of comments
   */
  async getComments({ token, owner, repo, issueNumber }) {
    const client = createClient(token);
    const cacheKey = `comments:${owner}:${repo}:${issueNumber}`;
    
    return getCachedOrFetch(cacheKey, async () => {
      const { data } = await client.rest.issues.listComments({
        owner,
        repo,
        issue_number: parseInt(issueNumber)
      });
      
      return data;
    });
  },
  
  /**
   * Create a new issue
   * @param {Object} params - Request parameters
   * @returns {Promise<Object>} Created issue
   */
  async createIssue({ token, owner, repo, title, body, labels = [] }) {
    const client = createClient(token);
    
    const { data } = await client.rest.issues.create({
      owner,
      repo,
      title,
      body,
      labels
    });
    
    // Invalidate issues cache
    Array.from(cache.keys())
      .filter(key => key.startsWith(`issues:${owner}:${repo}`))
      .forEach(key => cache.delete(key));
    
    return data;
  },
  
  /**
   * Add a comment to an issue
   * @param {Object} params - Request parameters
   * @returns {Promise<Object>} Created comment
   */
  async createComment({ token, owner, repo, issueNumber, body }) {
    const client = createClient(token);
    
    const { data } = await client.rest.issues.createComment({
      owner,
      repo,
      issue_number: parseInt(issueNumber),
      body
    });
    
    // Invalidate comments cache
    cache.delete(`comments:${owner}:${repo}:${issueNumber}`);
    
    return data;
  },
  
  /**
   * Search for issues
   * @param {Object} params - Search parameters
   * @returns {Promise<Array>} Search results
   */
  async searchIssues({ token, query, perPage = 30 }) {
    const client = createClient(token);
    const cacheKey = `search:${query}:${perPage}`;
    
    return getCachedOrFetch(cacheKey, async () => {
      const { data } = await client.rest.search.issuesAndPullRequests({
        q: query,
        per_page: perPage
      });
      
      return data.items;
    });
  },
  
  /**
   * Check GitHub API rate limits
   * @param {Object} params - Request parameters
   * @returns {Promise<Object>} Rate limit information
   */
  async getRateLimits({ token }) {
    const client = createClient(token);
    
    // Don't cache rate limits
    const { data } = await client.rest.rateLimit.get();
    return data.rate;
  }
};

module.exports = {
  ...api,
  clearCache
}; 