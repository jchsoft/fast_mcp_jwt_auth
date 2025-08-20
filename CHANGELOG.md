# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-08-19

### Added
- Initial release of FastMcp JWT Auth gem
- JWT token extraction from Authorization: Bearer headers
- Configurable JWT decoder callback for token decoding
- Configurable user finder callback for user lookup from decoded tokens
- Token validation with configurable callback (defaults to expiration check)
- Current user setter and resetter with configurable callbacks
- Automatic Rails integration via Railtie
- Lazy patch application for FastMcp::Transports::RackTransport
- Comprehensive test suite with mocked dependencies
- Error handling with graceful fallback to normal request processing
- Support for Rails 7.0+ and Ruby 3.1+

### Changed
- N/A (initial release)

### Deprecated  
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- N/A (initial release)