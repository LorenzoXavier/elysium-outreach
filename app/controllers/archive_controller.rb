class ArchiveController < ApplicationController
  def index
    @contacts = Contact.archived.order(updated_at: :desc)
  end
end
