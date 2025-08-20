# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "logger"
require "stringio"
require "json"

# Mock ActiveSupport for testing
class String
  def inquiry
    StringInquirer.new(self)
  end
end

class StringInquirer < String
  def test?
    self == "test"
  end

  def production?
    self == "production"
  end

  def development?
    self == "development"
  end
end

# Mock Rails environment for testing
module Rails
  class << self
    attr_accessor :logger
  end

  def self.env
    @env ||= "test".inquiry
  end

  def self.const_defined?(name)
    return true if name == "Server"

    super
  end

  # Initialize logger for tests
  self.logger = Logger.new(StringIO.new)

  class Railtie
    def self.initializer(name, options = {}, &)
      # Mock initializer registration
    end
  end
end

Rails.logger = Logger.new(StringIO.new)

# Mock Current for testing
class Current
  class << self
    attr_accessor :user
  end

  def self.reset
    self.user = nil
  end
end

# Mock Time.current for testing
class Time
  def self.current
    @current ||= Time.now
  end

  class << self
    attr_writer :current
  end
end

# Mock FastMcp for testing
module FastMcp
  module Transports
    class RackTransport
      attr_accessor :running, :handled_requests

      def initialize
        @running = false
        @handled_requests = []
      end

      def handle_mcp_request(request, env)
        @handled_requests << { request: request, env: env }
      end

      def running?
        @running
      end

      def clear_requests
        @handled_requests.clear
      end
    end
  end
end

# Mock Request object for testing
class MockRequest
  attr_accessor :env

  def initialize(env = {})
    @env = env
  end
end

require "fast_mcp_jwt_auth"
require "minitest/autorun"
