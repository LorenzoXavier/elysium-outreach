class EmailTemplate < ApplicationRecord
  has_many :scheduled_emails, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :subject, presence: true
  validates :body, presence: true
end
