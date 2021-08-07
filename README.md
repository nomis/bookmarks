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

* Lookup the title of pasted URLs server-side (for mobile clients that
  can't support bookmarklets)

## Copyright

    Copyright 2021  Simon Arlott

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
