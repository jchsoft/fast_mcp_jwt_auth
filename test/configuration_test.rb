# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def setup
    @config = FastMcpJwtAuth::Configuration.new
  end

  def test_default_values
    assert @config.enabled
    assert_nil @config.jwt_decoder
    assert_nil @config.user_finder
    refute_nil @config.token_validator
    refute_nil @config.current_user_setter
    refute_nil @config.current_resetter
  end

  def test_default_token_validator_checks_expiration
    # Token without expiration should be valid
    assert @config.token_validator.call({ user_id: 123 })

    # Token with future expiration should be valid
    future_exp = Time.current.to_i + 3600

    assert @config.token_validator.call({ user_id: 123, exp: future_exp })

    # Token with past expiration should be invalid
    past_exp = Time.current.to_i - 3600

    refute @config.token_validator.call({ user_id: 123, exp: past_exp })
  end

  def test_default_current_user_setter
    test_user = { id: 123, name: "Test User" }
    @config.current_user_setter.call(test_user)

    assert_equal test_user, Current.user
  end

  def test_default_current_resetter
    Current.user = { id: 123, name: "Test User" }
    @config.current_resetter.call

    assert_nil Current.user
  end

  def test_attributes_can_be_assigned
    decoder = ->(token) { { user_id: token } }
    finder = ->(decoded) { { id: decoded[:user_id] } }
    validator = ->(_decoded) { false }
    setter = ->(user) { Current.user = user }
    resetter = -> { Current.user = nil }

    @config.jwt_decoder = decoder
    @config.user_finder = finder
    @config.token_validator = validator
    @config.current_user_setter = setter
    @config.current_resetter = resetter
    @config.enabled = false

    assert_equal decoder, @config.jwt_decoder
    assert_equal finder, @config.user_finder
    assert_equal validator, @config.token_validator
    assert_equal setter, @config.current_user_setter
    assert_equal resetter, @config.current_resetter
    refute @config.enabled
  end
end
