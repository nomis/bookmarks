# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class BookmarkTag < ApplicationRecord
  belongs_to :bookmark
  belongs_to :tag
end
