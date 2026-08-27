class AddEmailSentAtToContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :contacts, :email_sent_at, :datetime
  end
end
