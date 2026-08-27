class OutreachMailer < ApplicationMailer
  def outreach_email(contact)
    @contact = contact
    mail(to: contact.email, subject: "Following up, #{contact.first_name.presence || contact.display_name}")
  end
end
