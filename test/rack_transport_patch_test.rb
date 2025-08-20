# frozen_string_literal: true

require "test_helper"

class TestRackTransportPatch < Minitest::Test
  def setup
    FastMcpJwtAuth.configuration = nil
    # Force reset patch application state
    FastMcpJwtAuth::RackTransportPatch.instance_variable_set(:@patch_applied, false)
    Current.reset
  end

  def teardown
    FastMcpJwtAuth.configuration = nil
    Current.reset
  end

  def test_patch_is_applied
    create_configured_transport

    assert_predicate FastMcpJwtAuth::RackTransportPatch, :patch_applied?
  end

  def test_transport_has_patched_methods
    transport = create_configured_transport

    assert_respond_to transport, :handle_mcp_request
  end

  def test_no_authorization_header_uses_default_behavior
    transport = create_configured_transport

    request = MockRequest.new({})
    transport.handle_mcp_request(request, {})

    # Should have processed request normally without authentication
    assert_equal 1, transport.handled_requests.length
    assert_nil Current.user
  end

  def test_invalid_authorization_header_ignored
    transport = create_configured_transport

    request = MockRequest.new({ "HTTP_AUTHORIZATION" => "Basic dXNlcjpwYXNz" })
    transport.handle_mcp_request(request, {})

    # Should have processed request normally, ignoring non-Bearer token
    assert_equal 1, transport.handled_requests.length
    assert_nil Current.user
  end

  def test_jwt_authentication_disabled_ignores_header
    # When disabled, patch is not applied at all
    FastMcpJwtAuth.configure { |c| c.enabled = false }
    FastMcpJwtAuth::RackTransportPatch.apply_patch!

    refute_predicate FastMcpJwtAuth::RackTransportPatch, :patch_applied?
  end

  def test_successful_jwt_authentication
    mock_user = { id: 123, email: "test@example.com" }
    user_during_request = nil
    decoder_called = false
    finder_called = false
    token_validator_called = false

    FastMcpJwtAuth.configure do |config|
      config.enabled = true
      config.jwt_decoder = lambda do |token|
        decoder_called = true
        return { user_id: 123, exp: nil } if token == "valid_token" # Remove expiration for simpler test

        nil
      end
      config.user_finder = lambda do |decoded|
        finder_called = true
        decoded[:user_id] == 123 ? mock_user : nil
      end
      config.token_validator = lambda do |_decoded|
        token_validator_called = true
        true # Always valid for this test
      end
      # Capture user during request
      config.current_user_setter = lambda do |user|
        Current.user = user
        user_during_request = user
      end
    end

    FastMcpJwtAuth::RackTransportPatch.apply_patch!
    transport = FastMcp::Transports::RackTransport.new
    transport.clear_requests

    request = MockRequest.new({ "HTTP_AUTHORIZATION" => "Bearer valid_token" })
    transport.handle_mcp_request(request, {})

    # Debug information
    assert decoder_called, "JWT decoder should have been called"
    assert token_validator_called, "Token validator should have been called"
    assert finder_called, "User finder should have been called"

    # Should have authenticated during request
    assert_equal mock_user, user_during_request
    # Should have processed request
    assert_equal 1, transport.handled_requests.length
    # Current user should be reset after request
    assert_nil Current.user
  end

  private

  def create_configured_transport(enabled: true)
    FastMcpJwtAuth.configure { |c| c.enabled = enabled }
    FastMcpJwtAuth::RackTransportPatch.apply_patch!
    transport = FastMcp::Transports::RackTransport.new
    transport.running = true
    transport.clear_requests
    transport
  end
end
