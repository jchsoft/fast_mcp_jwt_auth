# frozen_string_literal: true

require "test_helper"

class TestRailtie < Minitest::Test
  def setup
    # Reset configuration and patch state
    FastMcpJwtAuth.configuration = nil
    FastMcpJwtAuth::RackTransportPatch.instance_variable_set(:@patch_applied, false)

    # Create fresh mock logger to capture messages
    @mock_logger = MockLogger.new
    Rails.logger = @mock_logger
  end

  def teardown
    FastMcpJwtAuth.configuration = nil
    FastMcpJwtAuth::RackTransportPatch.instance_variable_set(:@patch_applied, false)
    Rails.logger = Logger.new(StringIO.new)
  end

  def test_railtie_applies_patch_when_enabled
    FastMcpJwtAuth.configure { |c| c.enabled = true }

    FastMcpJwtAuth::Railtie.apply_jwt_patch

    assert_predicate FastMcpJwtAuth::RackTransportPatch, :patch_applied?
    assert_includes @mock_logger.messages[:debug], "FastMcpJwtAuth: Attempting to apply RackTransport patch"
    assert_includes @mock_logger.messages[:info], "FastMcpJwtAuth: Applying JWT authentication patch to FastMcp::Transports::RackTransport"
  end

  def test_railtie_logs_disabled_status_when_disabled
    FastMcpJwtAuth.configure { |c| c.enabled = false }

    FastMcpJwtAuth::Railtie.log_disabled_status

    assert_includes @mock_logger.messages[:info], "FastMcpJwtAuth: JWT authentication disabled"
  end

  def test_railtie_inherits_from_rails_railtie
    assert_equal Rails::Railtie, FastMcpJwtAuth::Railtie.superclass
  end

  def test_public_methods_are_accessible
    # Test that helper methods are public and accessible
    assert_respond_to FastMcpJwtAuth::Railtie, :apply_jwt_patch
    assert_respond_to FastMcpJwtAuth::Railtie, :log_disabled_status
  end

  class MockLogger
    attr_reader :messages

    def initialize
      @messages = { debug: [], info: [], warn: [], error: [] }
    end

    %i[debug info warn error].each do |level|
      define_method(level) do |message|
        @messages[level] << message
      end
    end
  end
end
