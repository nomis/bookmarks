# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "#{Etc.getpwnam(Etc.getlogin).gecos.split(/,/).first} <#{Etc.getlogin}@#{Socket.gethostbyname(Socket.gethostname).first}>"
  layout "mailer"
end
