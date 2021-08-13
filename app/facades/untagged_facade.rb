# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

# Fake tag representing "no tags"
class UntaggedFacade
  def initialize(count, search_match)
    @count = count
    @search_match = search_match
  end

  def name
    "∅"
  end

  def count
    @count
  end

  def search_match?
    @search_match
  end

  def search_toggle_type
    search_match? ? :all : :untagged
  end
end
