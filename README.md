# FastMcp JWT Auth

**JWT Authorization header authentication extension for [FastMcp](https://github.com/yjacquin/fast-mcp) RackTransport.**

This gem extends the [FastMcp](https://github.com/yjacquin/fast-mcp) gem to enable JWT-based user authentication via Authorization headers in Rails applications. It provides configurable callbacks for token decoding, user lookup, and validation.

## Problem

FastMcp::Transports::RackTransport doesn't have built-in JWT authentication support. For integrating with external MCP clients that use JWT tokens for authentication, you need a way to:

1. Extract JWT tokens from Authorization headers
2. Decode and validate the tokens
3. Find users based on token payload
4. Set `Current.user` for the request duration

## Solution

This gem provides a monkey patch for `FastMcp::Transports::RackTransport` that:

1. Extracts JWT tokens from `Authorization: Bearer` headers
2. Decodes tokens using configurable callbacks
3. Validates token expiration and other claims
4. Finds users using configurable lookup logic
5. Sets `Current.user` for request duration
6. Cleans up `Current` after request processing

## Installation

**Prerequisites**: This gem requires the [fast-mcp](https://github.com/yjacquin/fast-mcp) gem to be installed first.

Add both gems to your application's Gemfile:

```ruby
gem 'fast-mcp'                                    # Required base gem
gem 'fast_mcp_jwt_auth', github: 'jchsoft/fast_mcp_jwt_auth'  # This extension
```

And then execute:

```bash
bundle install
```

**Note**: The `fast-mcp` gem provides the core MCP (Model Context Protocol) server functionality, while this gem extends it with JWT authentication support.

## Usage

### Automatic Integration

**No configuration needed for basic usage!** Just add the gem to your Gemfile and configure the callbacks.

The gem will:
- ✅ **Automatically patch** FastMcp::Transports::RackTransport during Rails initialization
- ✅ **Extract JWT tokens** from Authorization: Bearer headers automatically  
- ✅ **Use Rails.logger** for logging (no configuration required)
- ✅ **Handle errors gracefully** with fallback to normal request processing

### Configuration

Create an initializer to configure JWT decoding and user lookup:

```ruby
# config/initializers/fast_mcp_jwt_auth.rb
FastMcpJwtAuth.configure do |config|
  config.enabled = true
  
  # JWT token decoding callback
  config.jwt_decoder = ->(jwt_token) do
    JWT.decode(jwt_token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')[0]
  end
  
  # User lookup callback
  config.user_finder = ->(decoded_token) do
    User.find_by(authentication_token: decoded_token['authentication_token'])
  end
  
  # Optional: Token validation callback (defaults to expiration check)
  config.token_validator = ->(decoded_token) do
    decoded_token['exp'].nil? || decoded_token['exp'] >= Time.current.to_i
  end
  
  # Optional: Custom current user setter (defaults to Current.user=)
  config.current_user_setter = ->(user) do
    Current.user = user
  end
  
  # Optional: Custom context resetter (defaults to Current.reset)
  config.current_resetter = -> do
    Current.reset
  end
end
```

### WorkVector Integration Example

For WorkVector-style JWT integration using JwtIdClaim:

```ruby
# config/initializers/fast_mcp_jwt_auth.rb
FastMcpJwtAuth.configure do |config|
  config.enabled = true
  
  # Use JwtIdClaim for token decoding (WorkVector pattern)
  config.jwt_decoder = ->(jwt_token) do
    JwtIdClaim.decode(jwt_token)
  end
  
  # Find user by authentication_token from JWT payload
  config.user_finder = ->(decoded_token) do
    User.find_by(authentication_token: decoded_token[:authentication_token])
  end
end
```

## Configuration Callbacks

The gem provides these configurable callbacks:

- **`jwt_decoder`**: Callback for JWT token decoding (required)
- **`user_finder`**: Callback for user lookup from decoded token (required)  
- **`token_validator`**: Callback for token validation (optional, defaults to expiration check)
- **`current_user_setter`**: Callback for setting current user (optional, defaults to `Current.user=`)
- **`current_resetter`**: Callback for resetting current context (optional, defaults to `Current.reset`)

## How It Works

1. **Request Processing**: When FastMcp processes an MCP request, the patch intercepts it
2. **Header Extraction**: Looks for `Authorization: Bearer <token>` header
3. **Token Decoding**: Uses configured `jwt_decoder` callback to decode the JWT
4. **Token Validation**: Validates token using `token_validator` callback
5. **User Lookup**: Finds user using `user_finder` callback
6. **Context Setting**: Sets current user using `current_user_setter` callback
7. **Request Processing**: Continues with normal MCP request processing
8. **Cleanup**: Resets current context using `current_resetter` callback

## Error Handling

The gem handles errors gracefully:
- Invalid JWT tokens are logged as warnings but don't break request processing
- Missing or malformed Authorization headers are ignored silently
- Decoding errors fall back to normal request processing without authentication
- User lookup failures result in no authentication but normal request processing

## Requirements

- Ruby >= 3.1.0
- Rails >= 7.0
- FastMcp gem

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Testing

```bash
rake test
rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jchsoft/fast_mcp_jwt_auth.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).