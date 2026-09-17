# frozen_string_literal: true

require_relative "lib/rakuten_rms/version"

Gem::Specification.new do |spec|
  spec.name = "rakuten_rms"
  spec.version = RakutenRms::VERSION
  spec.authors = [ "Cody Baldwin" ]
  spec.email = [ "codybaldwin@gmail.com" ]
  spec.homepage = "https://github.com/cmbaldwin/RubyRakutenAPI"
  spec.summary = "Ruby client for Rakuten's RMS WEB SERVICE API"
  spec.description = "Talks to the RakutenPay Order API and Item API: ESA auth, " \
                     "the documented 1 req/sec throttle, automatic pagination and " \
                     "100-order batching, and typed errors for both RMS failure " \
                     "envelopes. No runtime dependencies."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/main/README.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*.rb", "docs/**/*.md", "LICENSE", "README.md", "CHANGELOG.md"]
  end
  spec.require_paths = [ "lib" ]

  spec.required_ruby_version = ">= 3.2.0"

  # Runtime dependencies: none. json, net/http and uri are stdlib.
end
