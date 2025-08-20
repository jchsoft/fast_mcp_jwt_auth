# frozen_string_literal: true

require_relative "lib/fast_mcp_jwt_auth/version"

Gem::Specification.new do |spec|
  spec.name = "fast_mcp_jwt_auth"
  spec.version = FastMcpJwtAuth::VERSION
  spec.authors = ["josefchmel"]
  spec.email = ["chmel@jchsoft.cz"]

  spec.summary = "JWT Authorization header authentication for FastMcp RackTransport"
  spec.description = "Enables FastMcp RackTransport to authenticate users via JWT tokens passed through Authorization headers with configurable callbacks for token decoding and user lookup"
  spec.homepage = "https://github.com/jchsoft/fast_mcp_jwt_auth"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jchsoft/fast_mcp_jwt_auth"
  spec.metadata["changelog_uri"] = "https://github.com/jchsoft/fast_mcp_jwt_auth/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "rails", ">= 7.0"

  # Development dependencies
  spec.add_development_dependency "jwt", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-minitest", "~> 0.25"
  spec.add_development_dependency "rubocop-rails", "~> 2.0"
end
