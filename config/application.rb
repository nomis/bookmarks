# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
#require "active_storage/engine"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "active_job/railtie"
#require "action_cable/engine"
#require "action_mailbox/engine"
#require "action_text/engine"
require "rails/test_unit/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bookmarks
  class CacheStaticContent
    def initialize(app, pattern, cache_control)
      @app = app
      @pattern = pattern
      @cache_control = cache_control
    end

    def call(env)
      status, headers, response = @app.call(env)

      if env["REQUEST_PATH"] =~ @pattern
        headers["Cache-Control"] = @cache_control
      end

      [status, headers, response]
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.autoload_paths << Rails.root.join("app", "facades")
    config.autoload_paths << Rails.root.join("app", "lib")

    # Rails (6.1.1) does not set Vary: correctly, so Accept: must be ignored
    config.action_dispatch.ignore_accept_header = true

    config.action_dispatch.cookies_same_site_protection = :strict

    # Applied to all file requests, used if Cache-Control is not supported by the client
    config.public_file_server.headers = {
      "Expires" => 1.day.from_now.httpdate,
    }

    # Different databases have different types and expression syntax
    require "active_record/database_configurations"
    db_adapter = ActiveRecord::DatabaseConfigurations
      .new(Rails.application.config.database_configuration)
      .configs_for(env_name: Rails.env)[0].adapter
    config.paths["db"] = "db/schema/#{db_adapter}"

    # Compress files with Brotli
    config.assets.configure do |env|
      env.register_exporter %w(text/css application/javascript image/svg+xml),
        Sprockets::ExportersPack::BrotliExporter
    end

    # Application config
    bm_def = YAML.load_file(Rails.root.join("config", "defaults", "bookmarks.yml"))
    cfg_file = Rails.root.join("config", "bookmarks.yml")
    cfg_file = Rails.root.join("config", "bookmarks.yml.sample") if !cfg_file.exist?
    bm_cfg = YAML.load_file(cfg_file)[Rails.env]
    config.x = OpenStruct.new(bm_def.deep_merge(bm_cfg))

    if config.x.source_code_name.blank? || config.x.source_code_url.blank?
      raise "Missing configuration of source code location"
    end

    Rails.application.default_url_options = config.x.base_url.to_hash.deep_symbolize_keys
    config.x.scm_revision = `git rev-parse HEAD`.strip
    config.x.scm_description = `git describe --dirty=+`.strip

    # After environment configuration
    config.before_initialize do
      if config.public_file_server.enabled
        # Apply Cache-Control only to content that doesn't change
        config.middleware.insert_before(ActionDispatch::Static,
          CacheStaticContent, %r{^/(assets|packs[^/]*/js)/},
          "maxage=#{10.years.to_i}, public, immutable")
      end
    end
  end
end
