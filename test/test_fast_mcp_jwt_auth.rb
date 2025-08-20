# frozen_string_literal: true

require "test_helper"

class TestFastMcpJwtAuth < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FastMcpJwtAuth::VERSION
  end

  def test_configuration_can_be_set
    FastMcpJwtAuth.configure do |config|
      config.enabled = false
    end

    refute FastMcpJwtAuth.config.enabled
  end

  def test_has_error_class
    assert_kind_of Class, FastMcpJwtAuth::Error
    assert_kind_of StandardError, FastMcpJwtAuth::Error.new
  end
end
