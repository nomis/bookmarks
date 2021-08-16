# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

# Fake tag representing visibility
class VisibilityTagFacade
  def initialize(type, count, search_match)
    @type = type
    @count = count
    @search_match = search_match
  end

  def name
    case @type
    when :public
      "🔓"
    when :private
      "🔒"
    end
  end

  def count
    @count
  end

  def search_match?
    @search_match
  end

  def search_toggle_type
    search_match? ? :any_visibility : @type
  end
end
