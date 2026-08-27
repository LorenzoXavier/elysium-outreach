class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      # Core CRM fields (from CSV imports like "Elysium CRM - Outreach.csv")
      t.string :full_name
      t.string :first_name
      t.string :last_name
      t.string :company
      t.string :title
      t.string :email
      t.string :phone
      t.string :linkedin_url
      t.string :website
      t.string :location
      t.text   :notes
      t.string :source

      # Pipeline / triage
      t.string :priority_status, null: false, default: "amber"

      # LinkedIn + email follow-up workflow
      t.datetime :linkedin_outreached_at
      t.datetime :email_followup_due_at
      t.string   :email_status, null: false, default: "pending"
      t.text     :email_body

      # Deduplication
      t.string     :duplicate_status, null: false, default: "unique"
      t.references :matched_contact, foreign_key: { to_table: :contacts }, null: true

      # Import batch tracking
      t.string :import_batch_id

      t.timestamps
    end

    add_index :contacts, :email
    add_index :contacts, :linkedin_url
    add_index :contacts, [:full_name, :company]
    add_index :contacts, :priority_status
    add_index :contacts, :duplicate_status
    add_index :contacts, :import_batch_id
  end
end
