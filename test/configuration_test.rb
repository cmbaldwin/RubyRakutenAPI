# frozen_string_literal: true

require_relative "test_helper"

module RakutenRms
  class ConfigurationTest < TestCase
    def test_authorization_is_esa_with_strict_base64_credentials
      config = Configuration.new
      config.service_secret = "SP123456_abcdef"
      config.license_key = "SL987654_ghijkl"

      assert_equal "ESA U1AxMjM0NTZfYWJjZGVmOlNMOTg3NjU0X2doaWprbA==", config.authorization
    end

    # encode64 wraps at 60 characters; a wrapped header is rejected by RMS.
    def test_authorization_never_contains_a_newline
      config = Configuration.new
      config.service_secret = "S" * 80
      config.license_key = "L" * 80

      refute_includes config.authorization, "\n"
    end

    def test_authorization_names_the_missing_credential
      config = Configuration.new
      config.service_secret = "present"
      config.license_key = "   "

      error = assert_raises(ConfigurationError) { config.authorization }
      assert_includes error.message, "license_key"
      refute_includes error.message, "service_secret"
    end

    def test_authorization_names_both_missing_credentials
      config = Configuration.new
      config.service_secret = nil
      config.license_key = nil

      error = assert_raises(ConfigurationError) { config.authorization }
      assert_includes error.message, "service_secret and license_key"
    end

    def test_defaults_come_from_the_environment
      with_env("RAKUTEN_SERVICE_SECRET" => "from-env", "RAKUTEN_LICENSE_KEY" => "key-env") do
        config = Configuration.new

        assert_equal "from-env", config.service_secret
        assert_equal "key-env", config.license_key
      end
    end

    def test_defaults_follow_the_documented_rms_limits
      config = Configuration.new

      assert_in_delta 1.0, config.request_gap, 0.001, "RMS documents 1 request/second"
      assert_equal 7, config.order_version, "version 7 is the oldest with SKU support"
      assert_equal "https://api.rms.rakuten.co.jp/es/2.0", config.base_url
    end

    def test_merge_applies_known_settings
      config = Configuration.new.merge!(request_gap: 0, order_version: 9)

      assert_equal 0, config.request_gap
      assert_equal 9, config.order_version
    end

    def test_merge_rejects_an_unknown_setting
      error = assert_raises(ConfigurationError) { Configuration.new.merge!(licence_key: "typo") }

      assert_includes error.message, "licence_key"
    end

    def test_configure_sets_process_wide_defaults
      RakutenRms.configure do |config|
        config.service_secret = "global"
        config.license_key = "global-key"
      end

      assert_equal "global", Client.new.config.service_secret
    end

    def test_client_overrides_do_not_leak_into_the_global_configuration
      RakutenRms.configure { |config| config.request_gap = 1.0 }

      Client.new(request_gap: 0).config.request_gap

      assert_in_delta 1.0, RakutenRms.configuration.request_gap, 0.001
    end

    def test_two_clients_hold_independent_credentials
      RakutenRms.configure { |config| config.service_secret = "shared" }

      shop_a = Client.new(license_key: "a")
      shop_b = Client.new(license_key: "b")

      assert_equal "a", shop_a.config.license_key
      assert_equal "b", shop_b.config.license_key
      assert_equal "shared", shop_b.config.service_secret
    end

    private

    def with_env(values)
      original = values.transform_values { |_| nil }.merge(ENV.slice(*values.keys))
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
