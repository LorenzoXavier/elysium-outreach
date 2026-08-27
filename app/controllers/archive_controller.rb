class ArchiveController < ApplicationController
  def index
    @pagy, @contacts = pagy(Contact.archived.order(updated_at: :desc))
  end
end
