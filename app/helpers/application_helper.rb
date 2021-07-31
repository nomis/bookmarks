# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

module ApplicationHelper
  include Pagy::Frontend

  def bookmarklet_uri
    'javascript:' \
    + '(function(d,e){' \
      + 'window.open("' \
        + Rails.application.routes.url_helpers.compose_bookmark_url \
        + '?uri="+e(d.location)' \
        + '+"&title="+e(d.title),' \
        + '"_blank")' \
    + '})' \
    + '(document,encodeURIComponent)'
  end
end
