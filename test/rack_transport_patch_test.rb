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
    captured_user = nil
    callbacks = setup_authentication_callbacks(mock_user) { |user| captured_user = user }

    transport = create_authenticated_transport(callbacks)
    request = MockRequest.new({ "HTTP_AUTHORIZATION" => "Bearer valid_token" })
    transport.handle_mcp_request(request, {})

    verify_jwt_authentication_success(callbacks, mock_user, captured_user, transport)
  end

  private

  def setup_authentication_callbacks(mock_user, &user_capture)
    {
      decoder_called: false,
      finder_called: false,
      token_validator_called: false,
      jwt_decoder: lambda do |token|
        return { user_id: 123, exp: nil } if token == "valid_token"

        nil
      end,
      user_finder: lambda do |decoded|
        decoded[:user_id] == 123 ? mock_user : nil
      end,
      token_validator: -> { true },
      user_capture: user_capture
    }
  end

  def create_authenticated_transport(callbacks)
    FastMcpJwtAuth.configure do |config|
      config.enabled = true
      config.jwt_decoder = lambda do |token|
        callbacks[:decoder_called] = true
        callbacks[:jwt_decoder].call(token)
      end
      config.user_finder = lambda do |decoded|
        callbacks[:finder_called] = true
        callbacks[:user_finder].call(decoded)
      end
      config.token_validator = lambda do |decoded|
        callbacks[:token_validator_called] = true
        callbacks[:token_validator].call(decoded)
      end
      config.current_user_setter = lambda do |user|
        Current.user = user
        callbacks[:user_capture].call(user)
      end
    end

    create_patched_transport
  end

  def create_patched_transport
    FastMcpJwtAuth::RackTransportPatch.apply_patch!
    transport = FastMcp::Transports::RackTransport.new
    transport.clear_requests
    transport
  end

  def verify_jwt_authentication_success(callbacks, mock_user, user_during_request, transport)
    assert callbacks[:decoder_called], "JWT decoder should have been called"
    assert callbacks[:token_validator_called], "Token validator should have been called"
    assert callbacks[:finder_called], "User finder should have been called"
    assert_equal mock_user, user_during_request
    assert_equal 1, transport.handled_requests.length
    assert_nil Current.user
  end

  def create_configured_transport(enabled: true)
    FastMcpJwtAuth.configure { |c| c.enabled = enabled }
    FastMcpJwtAuth::RackTransportPatch.apply_patch!
    transport = FastMcp::Transports::RackTransport.new
    transport.running = true
    transport.clear_requests
    transport
  end
end
