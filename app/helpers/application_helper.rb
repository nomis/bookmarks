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

  # Modified from https://github.com/ddnexus/pagy
  # tag 4.10.1 commit ca74132e8c4b007118faee26b1c6bd5460333f03 lib/pagy/frontend.rb
  #
  # The MIT License (MIT)
  #
  # Copyright (c) 2017-2021 Domizio Demichelis
  #
  # Permission is hereby granted, free of charge, to any person obtaining a copy
  # of this software and associated documentation files (the "Software"), to deal
  # in the Software without restriction, including without limitation the rights
  # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  # copies of the Software, and to permit persons to whom the Software is
  # furnished to do so, subject to the following conditions:
  #
  # The above copyright notice and this permission notice shall be included in
  # all copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  # THE SOFTWARE.
  def pagination_nav(pagy, pagy_id: nil, link_extra: '')
      p_id   = %( id="#{pagy_id}") if pagy_id
      link   = pagy_link_proc(pagy, link_extra: link_extra)
      p_prev = pagy.prev
      p_next = pagy.next

      html  = +%(<nav#{p_id} class="pagy-nav pagination" aria-label="pager"><ul>)
      html << if p_prev
                %(<li class="page prev">#{link.call p_prev, pagy_t('pagy.nav.prev'), 'aria-label="previous"'}</li> )
              else
                %(<li class="page prev disabled">#{pagy_t('pagy.nav.prev')}</li> )
              end
      pagy.series.each do |item|  # series example: [1, :gap, 7, 8, "9", 10, 11, :gap, 36]
        html << case item
                when Integer then %(<li class="page">#{link.call item}</li> )               # page link
                when String  then %(<li class="page active">#{item}</li> )                  # current page
                when :gap    then %(<li class="page gap">#{pagy_t('pagy.nav.gap')}</li> )   # page gap
                end
      end
      html << if p_next
                %(<li class="page next">#{link.call p_next, pagy_t('pagy.nav.next'), 'aria-label="next"'}</li>)
              else
                %(<li class="page next disabled">#{pagy_t('pagy.nav.next')}</li>)
              end
      html << %(</ul></nav>)
  end
end
