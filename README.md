# Bookmarks Website

Created to learn Ruby on Rails and host my own del.icio.us alternative.

## Requirements

* Bookmarks must have a title and a URI
* Bookmarks may be tagged
	* Tags are separated by spaces
	* Tags cannot contain spaces
    * Tags are case-insensitive
	* All tags share the same case
* Incremental searching by filtering on tags
	* Provide a list of all possible tags
	* Clicking on a tag adds or removes it from the filter
* Bookmarks are intended to be publicly visible
* Read-only unless logged in
* Single user so no self-registration
* No cookies, except for user login
* All basic functionality must work without JavaScript

## Features

* Lookup the title of URLs server-side (automatically on paste for mobile
  clients that can't support bookmarklets)

## Install

* Standard Ruby on Rails application
  * Install dependencies with `bundle install` and `yarn`
  * Database configuration is in [config/database.yml](config/database.yml.sample)
* Create a PostgreSQL database (setting `PGDATABASE`, etc. if required)
* Run `bin/setup` or perform the following steps:
  * Create sample configuration files by running `rails setup:config`
  * Generate a production `secret_key_base` by running `rails credentials:edit`
  * Create the database tables by running `rails db:prepare`
* Application-specific configuration is in [config/bookmarks.yml](config/bookmarks.yml.sample)
  * The `base_url` must be configured for email and bookmarklet links to work
  * The `source_code_url` must be changed if you modify the application (and you
    must publish the running source code)
* Set up your user by editing [db/seeds/users.rb.example](db/seeds/users.rb.example),
  saving it as `db/seeds/users.rb` and run `rails db:seed:users` to load it (or
  use the `rails console` to create a new Devise User)
* There is an example systemd user service in [systemd/rails.service](systemd/rails.service)
* Production assets must be precompiled with `rails assets:precompile` before use

## Copyright

    Copyright 2021-2025  Simon Arlott

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
