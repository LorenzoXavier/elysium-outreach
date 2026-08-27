class DuplicatesController < ApplicationController
  before_action :set_contact, only: [ :confirm, :mark_unique ]

  def index
    @duplicates = Contact.potential_duplicate.includes(:matched_contact).order(created_at: :desc)
  end

  # "Confirm Duplicate" -- this row really is the same person/company as an
  # existing contact, so discard it and keep the original.
  def confirm
    @contact.destroy!
    redirect_to duplicates_path, notice: "#{@contact.display_name} confirmed as duplicate and discarded."
  end

  # "Mark as Unique" -- this row is actually a distinct contact, so unlink it
  # and move it into the main outreach pipeline.
  def mark_unique
    @contact.update!(duplicate_status: :unique, matched_contact: nil)
    redirect_to duplicates_path, notice: "#{@contact.display_name} moved into the outreach pipeline."
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end
end
