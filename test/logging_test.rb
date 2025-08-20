# frozen_string_literal: true

require "test_helper"

class TestLogging < Minitest::Test
  def setup
    @mock_logger = MockLogger.new
    Rails.logger = @mock_logger
  end

  def teardown
    Rails.logger = Logger.new(StringIO.new)
  end

  def test_log_methods_are_defined
    %i[debug info warn error].each do |level|
      method_name = "log_#{level}"

      assert_respond_to FastMcpJwtAuth, method_name
    end
  end

  def test_log_debug_adds_prefix
    FastMcpJwtAuth.log_debug "Test debug message"

    assert_equal 1, @mock_logger.messages[:debug].size
    assert_equal "FastMcpJwtAuth: Test debug message", @mock_logger.messages[:debug].first
  end

  def test_log_info_adds_prefix
    FastMcpJwtAuth.log_info "Test info message"

    assert_equal 1, @mock_logger.messages[:info].size
    assert_equal "FastMcpJwtAuth: Test info message", @mock_logger.messages[:info].first
  end

  def test_log_warn_adds_prefix
    FastMcpJwtAuth.log_warn "Test warning message"

    assert_equal 1, @mock_logger.messages[:warn].size
    assert_equal "FastMcpJwtAuth: Test warning message", @mock_logger.messages[:warn].first
  end

  def test_log_error_adds_prefix
    FastMcpJwtAuth.log_error "Test error message"

    assert_equal 1, @mock_logger.messages[:error].size
    assert_equal "FastMcpJwtAuth: Test error message", @mock_logger.messages[:error].first
  end

  def test_logger_nil_safety
    Rails.logger = nil

    # Should not raise any errors
    assert_nil FastMcpJwtAuth.log_debug("Test")
    assert_nil FastMcpJwtAuth.log_info("Test")
    assert_nil FastMcpJwtAuth.log_warn("Test")
    assert_nil FastMcpJwtAuth.log_error("Test")
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
