class ScheduledEmail < ApplicationRecord
  belongs_to :contact
  belongs_to :email_template, optional: true

  enum :status, { scheduled: "scheduled", sent: "sent", failed: "failed", cancelled: "cancelled" },
       default: "scheduled", validate: true

  # Set by ContactsController#send_email_now to skip the future-date check --
  # not persisted, just a flag for the one request that creates and delivers
  # a ScheduledEmail in the same breath.
  attr_accessor :send_immediately

  validates :subject, presence: true
  validates :body, presence: true
  validates :scheduled_at, presence: true
  validate :scheduled_at_in_future, on: :create, unless: :send_immediately

  scope :upcoming, -> { scheduled.order(scheduled_at: :asc) }

  # Called by ScheduledContactEmailJob at the scheduled time. Idempotent --
  # a cancelled/already-sent record is left alone rather than re-delivered.
  def deliver!
    return unless scheduled?

    OutreachMailer.scheduled_email(self).deliver_now
    update!(status: :sent, sent_at: Time.current)
    contact.update!(email_status: :sent, email_body: body, email_sent_at: sent_at)
  rescue StandardError => e
    update!(status: :failed, error_message: e.message)
  end

  def cancel!
    update!(status: :cancelled) if scheduled?
  end

  private

  def scheduled_at_in_future
    return if scheduled_at.blank? || scheduled_at > Time.current

    errors.add(:scheduled_at, "must be in the future")
  end
end
