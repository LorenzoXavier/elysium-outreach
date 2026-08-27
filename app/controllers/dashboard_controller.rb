class DashboardController < ApplicationController
  def index
    @filters = filter_params
    base = @filters[:status] == "archived" ? Contact.archived : Contact.active_pipeline

    scope = Contact.apply_filters(base, @filters)
                   .order(Arel.sql("CASE priority_status WHEN 'green' THEN 0 WHEN 'amber' THEN 1 ELSE 2 END"))
                   .order(created_at: :asc)

    @pagy, @contacts = pagy(scope)
  end

  private

  def filter_params
    params.permit(:q, :priority, :linkedin_outreached, :overdue, :contacted_from, :contacted_to, :status)
          .to_h.symbolize_keys
  end
end
