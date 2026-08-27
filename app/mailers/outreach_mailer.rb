class OutreachMailer < ApplicationMailer
  def outreach_email(contact)
    @contact = contact
    mail(to: contact.email, subject: "Following up, #{contact.first_name.presence || contact.display_name}")
  end

  # Sent by ScheduledContactEmailJob at the contact-chosen delivery time, using
  # the subject/body composed (optionally from a template, optionally AI-assisted)
  # in the contact email composer.
  def scheduled_email(scheduled_email)
    @scheduled_email = scheduled_email
    @contact = scheduled_email.contact
    mail(to: @contact.email, subject: scheduled_email.subject)
  end
end
