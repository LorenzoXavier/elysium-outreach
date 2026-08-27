class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("OUTREACH_MAILER_FROM", "outreach@elysium.uk")
  layout "mailer"
end
