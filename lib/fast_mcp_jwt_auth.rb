# frozen_string_literal: true

require_relative "fast_mcp_jwt_auth/version"
require_relative "fast_mcp_jwt_auth/configuration"

# JWT Authorization header authentication for FastMcp RackTransport.
# Enables FastMcp RackTransport to authenticate users via JWT tokens passed through Authorization headers
# with configurable callbacks for token decoding and user lookup.
module FastMcpJwtAuth
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.config
    self.configuration ||= Configuration.new
  end

  # Simple logging helper - uses Rails.logger since this gem is Rails-specific
  def self.logger
    Rails.logger
  end
end

# Load patch after module is fully defined
require_relative "fast_mcp_jwt_auth/rack_transport_patch"
require_relative "fast_mcp_jwt_auth/railtie" if defined?(Rails)
