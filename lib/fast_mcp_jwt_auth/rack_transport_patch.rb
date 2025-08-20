# frozen_string_literal: true

# Monkey patch for FastMcp::Transports::RackTransport
# Adds JWT authentication support via Authorization header

module FastMcpJwtAuth
  # Lazy patch application - applies patch when FastMcp transport is first accessed
  module RackTransportPatch
    @patch_applied = false

    def self.apply_patch!
      if @patch_applied
        FastMcpJwtAuth.logger&.debug "FastMcpJwtAuth: RackTransport patch already applied, skipping"
        return
      end

      unless defined?(FastMcp::Transports::RackTransport)
        FastMcpJwtAuth.logger&.debug "FastMcpJwtAuth: FastMcp::Transports::RackTransport not defined yet, skipping patch"
        return
      end

      unless FastMcpJwtAuth.config.enabled
        FastMcpJwtAuth.logger&.debug "FastMcpJwtAuth: JWT authentication disabled, skipping patch"
        return
      end

      FastMcpJwtAuth.logger&.info "FastMcpJwtAuth: Applying JWT authentication patch to FastMcp::Transports::RackTransport"

      patch_transport_class
      @patch_applied = true
      FastMcpJwtAuth.logger&.info "FastMcpJwtAuth: JWT authentication patch applied successfully"
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

        jwt_token = auth_header.sub("Bearer ", "")
        FastMcpJwtAuth.logger&.debug "FastMcpJwtAuth: Extracted JWT token from Authorization header"

        authenticate_user_with_token(jwt_token)
      rescue StandardError => e
        FastMcpJwtAuth.logger&.warn "FastMcpJwtAuth: JWT token authentication failed: #{e.message}"
      end

      def authenticate_user_with_token(jwt_token)
        return unless FastMcpJwtAuth.config.jwt_decoder

        decoded_token = FastMcpJwtAuth.config.jwt_decoder.call(jwt_token)
        return unless decoded_token

        return unless token_valid?(decoded_token)

        user = find_user_from_token(decoded_token)
        assign_current_user(user) if user
      end

      def token_valid?(decoded_token)
        return true unless FastMcpJwtAuth.config.token_validator

        FastMcpJwtAuth.config.token_validator.call(decoded_token)
      end

      def find_user_from_token(decoded_token)
        return unless FastMcpJwtAuth.config.user_finder

        user = FastMcpJwtAuth.config.user_finder.call(decoded_token)
        FastMcpJwtAuth.logger&.debug "FastMcpJwtAuth: Authenticated user: #{user}" if user
        user
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
