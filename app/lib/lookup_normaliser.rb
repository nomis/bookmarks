# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class LookupNormaliser
  NORMALISER = lambda do |uri|
    uri = HTTP::URI.parse(uri)

    HTTP::URI.new(
      :scheme     => uri.normalized_scheme,
      :authority  => uri.normalized_authority,
      :path       => uri.path,
      :query      => uri.query,
      :fragment   => uri.fragment,
    )
  end
end
