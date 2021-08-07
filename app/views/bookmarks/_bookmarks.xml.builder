# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

user = user_signed_in?

xml.instruct!
xml.declare!(:DOCTYPE, :xbel, :PUBLIC,
	"+//IDN python.org//DTD XML Bookmark Exchange Language 1.0//EN//XML".freeze,
	"http://www.python.org/topics/xml/dtds/xbel-1.0.dtd".freeze)

xml.xbel(version: "1.0".freeze,
		"xmlns:a": "urn:oid:1.3.6.1.4.1.39777.1.0.3.1.1".freeze) do
	bookmarks.each do |bookmark|
		xml.bookmark(id: "bookmark_#{bookmark.id}",
				href: bookmark.uri,
				added: bookmark.created_at.iso8601,
				modified: bookmark.updated_at.iso8601) do
			xml.title(bookmark.title)
			xml.info do
				xml.metadata(owner: "urn:oid:1.3.6.1.4.1.39777.1.2.1.1".freeze) do
					bookmark.tags.each do |tag|
						xml.tag!("a:tag".freeze, id: "tag_#{tag.id}",
								added: tag.created_at.iso8601,
								modified: tag.updated_at.iso8601) do
							xml.tag!("a:name".freeze, tag.name)
						end
					end
					if user
						if bookmark.private?
							xml.tag!("a:private".freeze)
						else
							xml.tag!("a:public".freeze)
						end
					end
				end
			end
		end
	end
end
