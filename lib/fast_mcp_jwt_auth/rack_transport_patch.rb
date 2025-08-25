# frozen_string_literal: true

# Monkey patch for FastMcp::Transports::RackTransport
# Adds JWT authentication support via Authorization header

module FastMcpJwtAuth
  # Lazy patch application - applies patch when FastMcp transport is first accessed
  module RackTransportPatch
    @patch_applied = false

    def self.apply_patch!
      return FastMcpJwtAuth.log_debug("RackTransport patch already applied, skipping") if @patch_applied
      return FastMcpJwtAuth.log_debug("FastMcp::Transports::RackTransport not defined yet, skipping patch") unless defined?(FastMcp::Transports::RackTransport)
      return FastMcpJwtAuth.log_debug("JWT authentication disabled, skipping patch") unless FastMcpJwtAuth.config.enabled

      apply_patch_to_transport
    end

    def self.apply_patch_to_transport
      FastMcpJwtAuth.log_info "Applying JWT authentication patch to FastMcp::Transports::RackTransport"
      patch_transport_class
      @patch_applied = true
      FastMcpJwtAuth.log_info "JWT authentication patch applied successfully"
    end

    def self.patch_transport_class
      FastMcp::Transports::RackTransport.prepend(JwtAuthenticationPatch)
    end

    def self.patch_applied?
      @patch_applied
    end

    # The actual patch module that gets prepended
    module JwtAuthenticationPatch
      def handle_mcp_request(request, env)
        authenticate_user_from_jwt(request)
        super
      ensure
        clear_current_user
      end

      private

      def authenticate_user_from_jwt(request)
        extract_jwt_token(request)&.tap do |jwt_token|
          FastMcpJwtAuth.log_debug "Extracted JWT token from Authorization header (length: #{jwt_token.length} chars)"
          authenticate_user_with_token(jwt_token)
        end
      rescue StandardError => e
        log_authentication_error(e)
      end

      def extract_jwt_token(request)
        auth_header = request.env["HTTP_AUTHORIZATION"]
        return log_and_return("No Authorization header found in request") unless auth_header
        return log_and_return("Authorization header present but not Bearer token format: #{auth_header[0..20]}...") unless auth_header.start_with?("Bearer ")

        auth_header.sub("Bearer ", "")
      end

      def log_and_return(message)
        FastMcpJwtAuth.log_debug message
        nil
      end

      def log_authentication_error(exception)
        FastMcpJwtAuth.log_error "JWT token authentication failed with exception: #{exception.class.name} - #{exception.message}"
        FastMcpJwtAuth.log_debug "JWT authentication error backtrace: #{exception.backtrace&.first(3)&.join("; ")}"
      end

      def authenticate_user_with_token(jwt_token)
        return FastMcpJwtAuth.log_warn("JWT decoder not configured, skipping token authentication") unless FastMcpJwtAuth.config.jwt_decoder

        decode_and_authenticate_token(jwt_token)
      rescue StandardError => e
        FastMcpJwtAuth.log_error "JWT token decoding failed: #{e.class.name} - #{e.message}"
      end

      def decode_and_authenticate_token(jwt_token)
        FastMcpJwtAuth.log_debug "Attempting to decode JWT token"
        return FastMcpJwtAuth.log_warn("JWT decoder returned nil - token may be invalid or malformed") unless (decoded_token = FastMcpJwtAuth.config.jwt_decoder.call(jwt_token))

        FastMcpJwtAuth.log_debug "JWT token decoded successfully, checking validity"
        return unless token_valid?(decoded_token)

        FastMcpJwtAuth.log_debug "JWT token validation passed, looking up user"
        authenticate_found_user(find_user_from_token(decoded_token))
      end

      def authenticate_found_user(user)
        if user
          FastMcpJwtAuth.log_debug "Setting current user context"
          assign_current_user(user)
          FastMcpJwtAuth.log_info "User authentication completed successfully"
        else
          FastMcpJwtAuth.log_warn "Authentication failed: no user found for token"
        end
      end

      def token_valid?(decoded_token)
        return log_debug_and_return_true?("No token validator configured, considering token valid") unless FastMcpJwtAuth.config.token_validator

        validate_decoded_token(decoded_token)
      rescue StandardError => e
        FastMcpJwtAuth.log_error "Token validation failed with exception: #{e.class.name} - #{e.message}"
        false
      end

      def validate_decoded_token(decoded_token)
        FastMcpJwtAuth.log_debug "Running token validation"
        FastMcpJwtAuth.config.token_validator.call(decoded_token).tap do |valid|
          log_validation_result(valid)
        end
      end

      def log_validation_result(valid)
        if valid
          FastMcpJwtAuth.log_debug "Token validation passed"
        else
          FastMcpJwtAuth.log_warn "Token validation failed - validator returned falsy value"
        end
      end

      def log_debug_and_return_true?(message)
        FastMcpJwtAuth.log_debug message
        true
      end

      def find_user_from_token(decoded_token)
        return FastMcpJwtAuth.log_warn("User finder not configured, cannot authenticate user") unless FastMcpJwtAuth.config.user_finder

        lookup_user_from_decoded_token(decoded_token)
      rescue StandardError => e
        FastMcpJwtAuth.log_error "User lookup failed with exception: #{e.class.name} - #{e.message}"
        nil
      end

      def lookup_user_from_decoded_token(decoded_token)
        FastMcpJwtAuth.log_debug "Looking up user from decoded token"
        FastMcpJwtAuth.config.user_finder.call(decoded_token).tap do |user|
          log_user_lookup_result(user)
        end
      end

      def log_user_lookup_result(user)
        if user
          FastMcpJwtAuth.log_debug "User found successfully: #{user}"
        else
          FastMcpJwtAuth.log_warn "User finder returned nil - user may not exist or be inactive"
        end
      end

      def assign_current_user(user)
        FastMcpJwtAuth.config.current_user_setter&.call(user)
      end

      def clear_current_user
        FastMcpJwtAuth.config.current_resetter&.call
      end
    end
  end
end

# NOTE: Patch is automatically applied by Railtie initializer when Rails loads
