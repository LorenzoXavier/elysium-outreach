class CreateScheduledEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_emails do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :email_template, null: true, foreign_key: true

      t.string :subject, null: false
      t.text :body, null: false
      t.datetime :scheduled_at, null: false
      t.string :status, null: false, default: "scheduled"
      t.datetime :sent_at
      t.text :error_message

      t.timestamps
    end

    add_index :scheduled_emails, :status
    add_index :scheduled_emails, :scheduled_at
  end
end
