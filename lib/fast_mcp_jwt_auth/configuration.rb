# frozen_string_literal: true

module FastMcpJwtAuth
  # Configuration class for FastMcpJwtAuth gem settings
  class Configuration
    attr_accessor :enabled, :logger, :jwt_decoder, :user_finder, :token_validator,
                  :current_user_setter, :current_resetter

    def initialize
      @enabled = true
      @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
      @jwt_decoder = nil
      @user_finder = nil
      @token_validator = lambda do |decoded_token|
        decoded_token[:exp].nil? || decoded_token[:exp] >= Time.current.to_i
      end
      @current_user_setter = ->(user) { Current.user = user }
      @current_resetter = -> { Current.reset }
    end
  end
end
