class ApplicationMailer < ActionMailer::Base
  default from: "#{Etc.getpwnam(Etc.getlogin).gecos.split(/,/).first} <#{Etc.getlogin}@#{Socket.gethostbyname(Socket.gethostname).first}>"
  layout "mailer"
end
