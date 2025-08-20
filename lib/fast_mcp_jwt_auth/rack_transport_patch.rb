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
        auth_header = request.env["HTTP_AUTHORIZATION"]
        return unless auth_header&.start_with?("Bearer ")

        auth_header.sub("Bearer ", "").tap do |jwt_token|
          FastMcpJwtAuth.log_debug "Extracted JWT token from Authorization header"
          authenticate_user_with_token(jwt_token)
        end
      rescue StandardError => e
        FastMcpJwtAuth.log_warn "JWT token authentication failed: #{e.message}"
      end

      def authenticate_user_with_token(jwt_token)
        return unless FastMcpJwtAuth.config.jwt_decoder

        FastMcpJwtAuth.config.jwt_decoder.call(jwt_token)&.then do |decoded_token|
          return unless token_valid?(decoded_token)

          find_user_from_token(decoded_token)&.tap { |user| assign_current_user(user) }
        end
      end

      def token_valid?(decoded_token)
        return true unless FastMcpJwtAuth.config.token_validator

        FastMcpJwtAuth.config.token_validator.call(decoded_token)
      end

      def find_user_from_token(decoded_token)
        return unless FastMcpJwtAuth.config.user_finder

        FastMcpJwtAuth.config.user_finder.call(decoded_token).tap do |user|
          FastMcpJwtAuth.log_debug "Authenticated user: #{user}" if user
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
