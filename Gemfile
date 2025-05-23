source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 2.7.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.0'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.6.9'
gem 'pg', '~> 1.5.9'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  # Performance checking while developing
  gem 'bullet'

  gem 'rspec-rails'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'

  gem 'minitest-stub_any_instance'
  gem 'factory_bot_rails', '~> 6.2.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Database locking
gem 'with_advisory_lock', '~> 4.6.0'

# Misc
gem 'natural_sort', '~> 0.3.0'
gem 'addressable', '~> 2.8.0'
gem 'concurrent-ruby', '~> 1.1.9'

# Authentication
gem 'devise', '~> 4.8.0'

# Pagination
gem 'pagy', '~> 4.10.1'

# HTTP client/parser
gem 'http', '~> 4.4.1'
gem 'nokogiri', '~> 1.15.7'

# Improve XML escaping performance
gem 'fast_xs', '~> 0.8.0'

# Compress .css with Brotli
gem 'sprockets-exporters_pack', '~> 0.1.2'

# https://github.com/ruby/net-imap/issues/16#issuecomment-803086765
gem 'mail', '2.7.1'

# https://github.com/mikel/mail/pull/1472
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1")
  gem 'net-imap', require: false
  gem 'net-pop', require: false
  gem 'net-smtp', require: false
end
