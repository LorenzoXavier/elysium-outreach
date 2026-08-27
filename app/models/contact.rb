class Contact < ApplicationRecord
  belongs_to :matched_contact, class_name: "Contact", optional: true
  has_many :duplicate_candidates, class_name: "Contact", foreign_key: :matched_contact_id,
           inverse_of: :matched_contact, dependent: :nullify

  enum :priority_status, { green: "green", amber: "amber", red: "red" }, default: "amber", validate: true
  enum :email_status, { pending: "pending", drafted: "drafted", sent: "sent" }, default: "pending", validate: true
  enum :duplicate_status, { unique: "unique", potential_duplicate: "potential_duplicate" },
       default: "unique", validate: true

  scope :active_pipeline, -> { unique.where(priority_status: %w[green amber]) }
  scope :archived, -> { unique.red }
  scope :needing_followup, -> {
    active_pipeline.where.not(linkedin_outreached_at: nil).where.not(email_status: "sent")
  }

  before_save :sync_full_name

  def display_name
    full_name.presence || [first_name, last_name].compact_blank.join(" ").presence || email.presence || "(no name)"
  end

  def followup_overdue?
    linkedin_outreached_at.present? &&
      !sent? &&
      email_followup_due_at.present? &&
      email_followup_due_at <= Time.current
  end

  def mark_linkedin_outreached!
    update!(linkedin_outreached_at: Time.current, email_followup_due_at: 1.week.from_now)
  end

  private

  def sync_full_name
    self.full_name = full_name.presence || [first_name, last_name].compact_blank.join(" ").presence
  end
end
