class ArchiveController < ApplicationController
  def index
    @pagy, @contacts = pagy(Contact.archived.order(created_at: :asc))
  end
end
