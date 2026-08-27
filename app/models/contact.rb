class Contact < ApplicationRecord
  belongs_to :matched_contact, class_name: "Contact", optional: true
  has_many :duplicate_candidates, class_name: "Contact", foreign_key: :matched_contact_id,
           inverse_of: :matched_contact, dependent: :nullify
  has_many :scheduled_emails, dependent: :destroy

  enum :priority_status, { green: "green", amber: "amber", red: "red" }, default: "amber", validate: true
  enum :email_status, { pending: "pending", drafted: "drafted", sent: "sent" }, default: "pending", validate: true
  enum :duplicate_status, { unique: "unique", potential_duplicate: "potential_duplicate" },
       default: "unique", validate: true

  PRIORITY_LABELS = { "green" => "High", "amber" => "Medium", "red" => "Low" }.freeze

  # The fields a person actually fills in on the contact form (as opposed to the
  # app-managed workflow fields like priority_status, email_status, etc.) --
  # this is what free-text search matches against.
  SEARCHABLE_FIELDS = %i[
    full_name first_name last_name company title email phone linkedin_url website location notes source
  ].freeze

  scope :active_pipeline, -> { unique.where(priority_status: %w[green amber]) }
  scope :archived, -> { unique.red }
  scope :needing_followup, -> {
    active_pipeline.where.not(linkedin_outreached_at: nil).where.not(email_status: "sent")
  }
  scope :overdue_for_followup, -> {
    where.not(linkedin_outreached_at: nil).where.not(email_status: "sent").where(email_followup_due_at: ..Time.current)
  }
  scope :search, ->(query) {
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    conditions = SEARCHABLE_FIELDS.map { |field| "#{field} ILIKE :pattern" }.join(" OR ")
    where(conditions, pattern: pattern)
  }

  before_save :sync_full_name

  # Applies the Dashboard filter bar's params (priority / linkedin_outreached /
  # overdue / contacted_from / contacted_to) on top of a base scope.
  def self.apply_filters(scope, filters)
    filters ||= {}

    scope = scope.search(filters[:q]) if filters[:q].present?
    scope = scope.where(priority_status: filters[:priority]) if filters[:priority].present?

    case filters[:linkedin_outreached]
    when "yes" then scope = scope.where.not(linkedin_outreached_at: nil)
    when "no" then scope = scope.where(linkedin_outreached_at: nil)
    end

    scope = scope.overdue_for_followup if filters[:overdue].present?

    if filters[:contacted_from].present?
      scope = scope.where(linkedin_outreached_at: Date.parse(filters[:contacted_from]).beginning_of_day..)
    end

    if filters[:contacted_to].present?
      scope = scope.where(linkedin_outreached_at: ..Date.parse(filters[:contacted_to]).end_of_day)
    end

    scope
  rescue ArgumentError
    scope
  end

  def display_name
    full_name.presence || [ first_name, last_name ].compact_blank.join(" ").presence || email.presence || "(no name)"
  end

  def priority_label
    PRIORITY_LABELS.fetch(priority_status)
  end

  def followup_overdue?
    linkedin_outreached_at.present? &&
      !sent? &&
      email_followup_due_at.present? &&
      email_followup_due_at <= Time.current
  end

  # Short status line for the pipeline list/table views: once the email is
  # sent, show when -- "Follow-up due" only ever applies to a not-yet-sent,
  # actually-overdue contact, not a generic upcoming date.
  def followup_status_text
    if sent?
      email_sent_at.present? ? "Followed up on #{email_sent_at.to_date.to_fs(:long)}" : "Followed up"
    elsif followup_overdue?
      "Follow-up due #{email_followup_due_at.to_date.to_fs(:long)}"
    end
  end

  def mark_linkedin_outreached!
    update!(linkedin_outreached_at: Time.current, email_followup_due_at: 1.week.from_now)
  end

  private

  def sync_full_name
    self.full_name = full_name.presence || [ first_name, last_name ].compact_blank.join(" ").presence
  end
end
