class ScheduledEmailsController < ApplicationController
  def index
    @scheduled_emails = ScheduledEmail.includes(:contact).order(scheduled_at: :desc)
  end

  def cancel
    scheduled_email = ScheduledEmail.find(params[:id])
    scheduled_email.cancel!
    redirect_back fallback_location: scheduled_emails_path, notice: "Scheduled email cancelled."
  end
end
