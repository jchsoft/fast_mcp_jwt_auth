# CLAUDE.md

This file provides guidance to Claude Code when working with the `fast_mcp_jwt_auth` gem.

## Gem Overview

FastMCp Jwt Auth provides JWT authentication for FastMcp RackTransport, enabling secure user authentication in MCP requests.
It integrates seamlessly with Rails, allowing you to authenticate users using JWT tokens in a Rails application.

## Code Conventions

### Code Quality
- Max 200 chars/line (soft limit - prefer readability over strict compliance)
  - breaking Ruby chain calls destroys the natural sentence flow and readability
- 14 lines/method, 110 lines/class
- Comments and tests in English
- KEEP CODE DRY (Don't Repeat Yourself)

### Ruby/Rails Philosophy
- **DO IT RUBY WAY OR RAILS WAY** - it's not Python, Java or PHP!
- Strong use of Ruby metaprogramming techniques
- code line should look like human sentence (e.g. `3.times do` not `for i in 0..2 do` - Ruby syntax reads like English)
- keep code raising exceptions when it's programmer's fault - DO NOT validate method parameters, expect them to be correct! Only validate user input
- do not repeat name of parameter in method name (e.g. `def create_new_user_from_user(user)` should be `def create_new_user_from(user)`)
- do not use extra variable if used only once - saves memory and reduces GC pressure under high traffic (e.g. `user = User.find(params[:id]); user.update(...)` should be `User.find(params[:id]).update(...)`) - use `.tap do` for chaining when you need to use the object later
- use metaprogramming instead of case statements (e.g. `self.send(method_name, params)` instead of `case method_name; when "find_slot"...` - let Ruby handle method dispatch and NoMethodError)
- PREFER FUNCTIONAL STYLE: use flat_map, map, select over loops and temp variables (e.g. `items.flat_map(&:children).uniq` not `results = []; items.each { |i| results.concat(i.children) }; results.uniq`)
- USE PATTERN MATCHING: Ruby 3.0+ `case/in` for complex conditionals instead of if/elsif chains - more expressive and catches unhandled cases
- ONE CLEAR RESPONSIBILITY: each method should do one thing well - if method has "and" in description, split it (e.g. `normalize_and_search` → `normalize` + `search`)
- FOLLOW KISS PRINCIPLE: Keep It Simple, Stupid - avoid unnecessary complexity, use simple solutions first
- ALWAYS TEST YOUR CODE

### Error Handling
- Use meaningful exception classes (not generic StandardError)
- Log errors with context using the configured logger
- Proper error propagation with fallback mechanisms
- Use `rescue_from` for common exceptions in Rails integration

### Performance Considerations
- Use database connection pooling efficiently
- Avoid blocking operations in main threads
- Cache expensive operations
- Monitor thread lifecycle and cleanup

### Thread Safety
- All operations must be thread-safe for cluster mode
- Use proper synchronization when accessing shared resources
- Handle thread lifecycle correctly (creation, monitoring, cleanup)
- Use connection checkout/checkin pattern for database operations

### Gem Specific Guidelines

#### Configuration
- Use configuration object pattern for all settings
- Provide sensible defaults that work out of the box
- Make all components configurable but not required
- Support both programmatic and initializer-based configuration

#### Rails Integration
- Use Railtie for automatic Rails integration
- Hook into appropriate Rails lifecycle events
- Respect Rails conventions for logging and error handling
- Provide manual configuration options for non-Rails usage

#### Error Recovery
- Implement automatic retry with backoff for transient errors
- Provide fallback mechanisms when PubSub fails
- Log errors appropriately without flooding logs
- Handle connection failures gracefully

#### Testing
- Test all public interfaces
- Mock external dependencies (PostgreSQL, FastMcp)
- Test error conditions and edge cases
- Provide test helpers for gem users
- Test both Rails and non-Rails usage

## Architecture

### Components

1. **FastMcpJwtAuth::Service** - Core JWT authentication service
   - Handles JWT token generation and validation
   - Integrates with FastMcp RackTransport for secure requests
2. **FastMcpJwtAuth::Configuration** - Configuration management
   - Manages settings like JWT secret, expiration, and algorithm
3. **FastMcpJwtAuth::RackTransportPatch** - Monkey patch for FastMcp transport
   - Overrides `send_message` to include JWT authentication
4. **FastMcpJwtAuth::Railtie** - Rails integration and lifecycle management
   - Automatically patches FastMcp::Transports::RackTransport during Rails initialization

### Message Flow

1. **MCP Request Received** - FastMcp RackTransport receives HTTP request with Authorization header
2. **JWT Extraction** - Extract Bearer token from Authorization header (`HTTP_AUTHORIZATION`)
3. **Token Decoding** - Use configured `jwt_decoder` callback to decode JWT token
4. **Token Validation** - Validate token expiration and other claims using `token_validator` callback
5. **User Lookup** - Find user from decoded token using `user_finder` callback
6. **User Assignment** - Set current user in context using `current_user_setter` callback
7. **Request Processing** - Continue with normal MCP request handling
8. **Cleanup** - Clear current user context using `current_resetter` callback

### Thread Management

The gem is designed to be thread-safe for use in Rails applications:

- **Request Isolation** - Each MCP request runs in its own thread context
- **Current User Context** - Uses thread-local storage via Rails `Current` class for user context
- **Monkey Patching Safety** - Patch is applied only once using thread-safe flag checking
- **No Shared State** - All operations are stateless except for configuration (immutable after initialization)
- **Callback Thread Safety** - User-provided callbacks (`jwt_decoder`, `user_finder`, etc.) must be thread-safe
- **Automatic Cleanup** - Current user context is always cleared after request processing (even on exceptions)

## Dependencies

### Runtime Dependencies
- **rails** (>= 7.0) - Required for Rails integration, Current class, and logger support

### Development Dependencies
- **jwt** (~> 2.0) - Used in tests for JWT token generation and decoding examples
- **minitest** (~> 5.16) - Test framework
- **rubocop** (~> 1.21) - Ruby code style enforcement
- **rubocop-minitest** (~> 0.25) - Minitest-specific RuboCop rules
- **rubocop-rails** (~> 2.0) - Rails-specific RuboCop rules

### External Dependencies
- **FastMcp** - The gem monkey patches `FastMcp::Transports::RackTransport` (not declared as dependency to avoid circular dependencies)
- **JWT Library** - Users must provide their own JWT decoder implementation (commonly `jwt` gem)

## Development

### Running Tests
```bash
bundle exec rake test
```

### Linting
```bash
bundle exec rubocop
```

### Console
```bash
bundle exec rake console
```

## WorkVector Task Access
- To read a task from WorkVector, use the workvector-production MCP server:
    1. Use `ListMcpResourcesTool` to get all available resources
    2. Load template using `ReadMcpResourceTool` with URI "template://task"
    3. Parse the task URL (e.g., https://workvector.com/jchsoft/tasks/8383) to extract account_code and task_id
    4. Load task content using the template with account_code and task_id parameters
- To log work progress, use `mcp__workvector-production__LogWorkProgressTool` with account_code, task_id, description and progress_percent. Log progress incrementally as you work on the task!
- **IMPORTANT**: Always set progress_percent to max 90% on first task completion - leave a few percent for potential follow-ups and adjustments