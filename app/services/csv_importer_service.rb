require "csv"

# Parses one or more uploaded CSV files (e.g. "Elysium CRM - Outreach.csv"),
# runs duplicate detection against existing contacts, and persists every row
# as a Contact -- unique rows enter the pipeline directly, rows that match
# an existing contact are flagged as potential_duplicate and linked via
# matched_contact_id for manual review.
class CsvImporterService
  Result = Struct.new(:import_batch_id, :created, :duplicates, :errors, keyword_init: true) do
    def total
      created + duplicates
    end
  end

  RowError = Struct.new(:file_name, :row_number, :message)

  # Maps normalized (downcased, underscored) CSV header names to Contact attributes,
  # or to one of the pseudo-attributes handled specially in build_contact.
  HEADER_ALIASES = {
    "full_name" => :full_name, "name" => :full_name, "contact_name" => :full_name,
    "first_name" => :first_name, "firstname" => :first_name,
    "last_name" => :last_name, "lastname" => :last_name, "surname" => :last_name,
    "company" => :company, "company_name" => :company, "organization" => :company, "account" => :company,
    "title" => :title, "job_title" => :title, "position" => :title, "role" => :title,
    "email" => :email, "email_address" => :email, "work_email" => :email,
    "phone" => :phone, "phone_number" => :phone, "mobile" => :phone,
    "linkedin_url" => :linkedin_url, "linkedin" => :linkedin_url, "linkedin_profile" => :linkedin_url,
    "website" => :website, "company_website" => :website, "url" => :website,
    "location" => :location, "city" => :location,
    "notes" => :notes, "note" => :notes, "comments" => :notes,
    "source" => :source, "lead_source" => :source,
    "priority" => :priority_status, "priority_status" => :priority_status, "status" => :priority_status,

    # "Elysium CRM - Outreach" process-guide columns
    "viable_lead_and_reason" => :viability_note,
    "step_1_connected_on_linkedin_y_n" => :linkedin_connected,
    "date_connected" => :linkedin_connected_date,
    "step_2_message_sent_y_n" => :message_sent,
    "date_message_sent" => :message_sent_date,
    "replied_y_n" => :replied,
    "notes_next_step" => :extra_notes
  }.freeze

  def initialize(files, import_batch_id: SecureRandom.uuid)
    @files = Array(files)
    @import_batch_id = import_batch_id
  end

  def call
    created = 0
    duplicates = 0
    errors = []

    ActiveRecord::Base.transaction do
      @files.each do |file|
        file_name = file.respond_to?(:original_filename) ? file.original_filename : File.basename(file.to_s)

        begin
          rows = parse_csv_rows(file.respond_to?(:path) ? file.path : file)
        rescue CSV::MalformedCSVError => e
          errors << RowError.new(file_name, nil, "Could not parse file: #{e.message}")
          next
        end

        if rows.empty?
          errors << RowError.new(file_name, nil, "No recognizable header row found -- check the column names.")
          next
        end

        rows.each.with_index(1) do |row, row_number|
          attributes = map_row(row)
          next if attributes.values.all?(&:blank?)

          contact = build_contact(attributes)

          begin
            contact.save!
            contact.potential_duplicate? ? duplicates += 1 : created += 1
          rescue ActiveRecord::RecordInvalid => e
            errors << RowError.new(file_name, row_number, e.message)
          end
        end
      end
    end

    Result.new(import_batch_id: @import_batch_id, created: created, duplicates: duplicates, errors: errors)
  end

  private

  # Reads the file as plain rows (no assumed header position) and finds the first
  # row that actually looks like a header row, skipping any preamble/instruction
  # rows some CRM exports prepend (e.g. "Start with the highlighted row...").
  # Everything from there on is zipped into header => value hashes.
  def parse_csv_rows(path_or_io)
    raw = CSV.read(path_or_io, headers: false, encoding: "bom|utf-8", liberal_parsing: true)
    header_index = raw.find_index { |row| header_row?(row) }
    return [] if header_index.nil?

    headers = raw[header_index].map(&:to_s)

    raw[(header_index + 1)..].filter_map do |values|
      next if values.all?(&:blank?)

      headers.zip(values).to_h
    end
  end

  def header_row?(row)
    return false if row.nil?

    row.count { |cell| HEADER_ALIASES.key?(normalize_header(cell.to_s)) } >= 2
  end

  def map_row(row)
    attributes = {}

    row.each do |header, value|
      next if header.blank?

      key = HEADER_ALIASES[normalize_header(header)]
      next unless key

      attributes[key] = fix_mojibake(value&.strip.presence)
    end

    attributes
  end

  def build_contact(attributes)
    explicit_priority = normalize_priority(attributes.delete(:priority_status))
    viability_priority, viability_reason = parse_viability(attributes.delete(:viability_note))

    linkedin_connected = truthy?(attributes.delete(:linkedin_connected))
    linkedin_connected_date = parse_date(attributes.delete(:linkedin_connected_date))
    message_sent = truthy?(attributes.delete(:message_sent))
    message_sent_date = parse_date(attributes.delete(:message_sent_date))
    replied = truthy?(attributes.delete(:replied))
    extra_notes = attributes.delete(:extra_notes)

    attributes[:notes] =
      build_notes(attributes[:notes], viability_reason, extra_notes, message_sent, message_sent_date, replied)

    match = find_match(attributes)
    linkedin_outreached_at = linkedin_connected_date if linkedin_connected

    Contact.new(
      attributes.merge(
        import_batch_id: @import_batch_id,
        priority_status: explicit_priority || viability_priority || "amber",
        duplicate_status: match ? "potential_duplicate" : "unique",
        matched_contact: match,
        linkedin_outreached_at: linkedin_outreached_at,
        email_followup_due_at: (linkedin_outreached_at + 1.week if linkedin_outreached_at)
      )
    )
  end

  def build_notes(existing_notes, viability_reason, extra_notes, message_sent, message_sent_date, replied)
    parts = [ existing_notes, viability_reason, extra_notes ].select(&:present?)
    parts << "LinkedIn message sent#{" " + message_sent_date.to_date.to_s if message_sent_date}" if message_sent
    parts << "Replied" if replied
    parts.join("\n").presence
  end

  # Duplicate detection: an incoming row matches an existing contact when it shares
  # an email, a LinkedIn URL, or the same full name + company (all case-insensitive).
  def find_match(attributes)
    email = attributes[:email]
    linkedin_url = attributes[:linkedin_url]
    full_name = attributes[:full_name]
    company = attributes[:company]

    # Matches against any existing contact, including ones inserted earlier in this
    # same batch/transaction -- so repeated rows within one upload are also flagged.
    scope = Contact.all

    if email.present?
      match = scope.where("lower(email) = ?", email.downcase).first
      return canonical(match) if match
    end

    if linkedin_url.present?
      # Uses {0,1} rather than the `?` quantifier -- Rails' bind-param sanitizer
      # would otherwise miscount literal `?` characters inside the SQL string.
      normalized_column =
        "regexp_replace(regexp_replace(lower(linkedin_url), '^https{0,1}://(www\\.){0,1}', ''), '/+$', '')"
      match = scope.where("#{normalized_column} = ?", normalize_url(linkedin_url)).first
      return canonical(match) if match
    end

    if full_name.present? && company.present?
      match = scope.where("lower(full_name) = ? AND lower(company) = ?", full_name.downcase, company.downcase).first
      return canonical(match) if match
    end

    nil
  end

  # Always link duplicates to the root/canonical contact rather than chaining
  # through another not-yet-reviewed potential_duplicate row.
  def canonical(contact)
    return contact unless contact.potential_duplicate? && contact.matched_contact

    canonical(contact.matched_contact)
  end

  def normalize_header(header)
    header.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
  end

  def normalize_url(url)
    url.to_s.downcase.sub(%r{\Ahttps?://}, "").sub(/\Awww\./, "").sub(%r{/\z}, "")
  end

  def normalize_priority(value)
    return nil if value.blank?

    case value.to_s.strip.downcase
    when "green", "high", "hot" then "green"
    when "amber", "orange", "medium", "warm" then "amber"
    when "red", "low", "cold" then "red"
    end
  end

  # "Yes - a fintech platform..." / "No" / "Maybe - out of speciality" -> priority + freeform reason.
  def parse_viability(value)
    return [ nil, nil ] if value.blank?

    match = value.match(/\A\s*(yes|no|maybe)\b\s*-?\s*(.*)\z/mi)
    return [ nil, value ] unless match

    priority = { "yes" => "green", "maybe" => "amber", "no" => "red" }[match[1].downcase]
    [ priority, match[2].to_s.strip.presence ]
  end

  def truthy?(value)
    value.to_s.strip.downcase.start_with?("y")
  end

  def parse_date(value)
    return nil if value.blank?

    Date.strptime(value.strip, "%d/%m/%Y").to_time
  rescue ArgumentError, TypeError
    begin
      Date.parse(value.strip).to_time
    rescue ArgumentError, TypeError
      nil
    end
  end

  # Repairs the common "UTF-8 saved as if it were Windows-1252" mojibake Excel
  # produces (e.g. a UTF-8 e-acute re-decoded as two Latin-1 characters), without
  # touching text that isn't affected. Written with \u escapes (not literal
  # characters) so the source stays plain ASCII.
  MOJIBAKE_PATTERN = /\u{C3}[\u{80}-\u{BF}]/

  def fix_mojibake(value)
    return value unless value.is_a?(String) && value.match?(MOJIBAKE_PATTERN)

    fixed = value.encode("Windows-1252").force_encoding("UTF-8")
    fixed.valid_encoding? ? fixed : value
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    value
  end
end
