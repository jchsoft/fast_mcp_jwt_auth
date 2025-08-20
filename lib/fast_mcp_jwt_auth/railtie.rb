# frozen_string_literal: true

module FastMcpJwtAuth
  # Rails integration for automatic FastMcpJwtAuth setup
  class Railtie < Rails::Railtie
    # Apply patch to FastMcp::Transports::RackTransport after all initializers are loaded
    initializer "fast_mcp_jwt_auth.apply_patch", after: :load_config_initializers do
      Rails.application.config.after_initialize do
        FastMcpJwtAuth.config.enabled ? FastMcpJwtAuth::Railtie.apply_jwt_patch : FastMcpJwtAuth::Railtie.log_disabled_status
      end
    end

    class << self
      def apply_jwt_patch
        FastMcpJwtAuth.log_debug "Attempting to apply RackTransport patch"
        FastMcpJwtAuth::RackTransportPatch.apply_patch!
      end

      def log_disabled_status
        FastMcpJwtAuth.log_info "JWT authentication disabled"
      end
    end
  end
end
