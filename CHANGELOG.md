# Changelog

## [Unreleased]

### Added
- Health check module (`lua/issues-neovim/health.lua`) for diagnostics via `:checkhealth issues-neovim`
- Comprehensive error handling with detailed diagnostic information
- Better troubleshooting information when issues fail to load
- Retry logic for API requests to handle intermittent failures

### Fixed
- Improved error messaging when GitHub token is invalid
- Better handling of repository detection errors
- More helpful guidance when API requests fail

### Changed
- Updated README with more detailed installation instructions and troubleshooting tips
- Improved plugin startup with better dependency checks
- Enhanced error messages with specific troubleshooting guidance 