# frozen_string_literal: true

module FastMcpJwtAuth
  # Rails integration for automatic FastMcpJwtAuth setup
  class Railtie < Rails::Railtie
    # Apply patch to FastMcp::Transports::RackTransport after all initializers are loaded
    initializer "fast_mcp_jwt_auth.apply_patch", after: :load_config_initializers do
      Rails.application.config.after_initialize do
        if FastMcpJwtAuth.config.enabled
          FastMcpJwtAuth.logger&.debug "FastMcpJwtAuth: Attempting to apply RackTransport patch"
          FastMcpJwtAuth::RackTransportPatch.apply_patch!
        else
          FastMcpJwtAuth.logger&.info "FastMcpJwtAuth: JWT authentication disabled"
        end
      end
    end
  end
end
