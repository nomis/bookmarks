# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

json.page @list.pagination.page
json.bookmarks render partial: "list_bookmarks.html"
json.pagination render partial: "list_pagination.html"
