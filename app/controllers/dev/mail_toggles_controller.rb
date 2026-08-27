module Dev
  class MailTogglesController < ApplicationController
    before_action :ensure_development!

    def update
      RealEmailToggle.toggle!
      redirect_back fallback_location: root_path,
                     notice: "Real emails are now #{RealEmailToggle.enabled? ? "ON" : "OFF"}."
    end

    private

    def ensure_development!
      head :not_found unless Rails.env.development?
    end
  end
end
