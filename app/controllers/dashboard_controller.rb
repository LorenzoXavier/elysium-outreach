class DashboardController < ApplicationController
  def index
    @contacts = Contact.active_pipeline
                        .order(Arel.sql("CASE priority_status WHEN 'green' THEN 0 WHEN 'amber' THEN 1 ELSE 2 END"))
                        .order(updated_at: :desc)
  end
end
