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

    # Rails (6.1.1) does not set Vary: correctly, so Accept: must be ignored
    config.action_dispatch.ignore_accept_header = true

    config.x = OpenStruct.new(YAML.load_file(Rails.root.join("config/bookmarks.yml"))[Rails.env])
    Rails.application.default_url_options = config.x.base_url.to_hash.deep_symbolize_keys

    config.action_dispatch.cookies_same_site_protection = :strict
  end
end
