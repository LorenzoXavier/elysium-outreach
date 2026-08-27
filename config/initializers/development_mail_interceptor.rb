if Rails.env.development?
  # Reroutes every outgoing email to local Mailpit unless RealEmailToggle is
  # switched on, regardless of the real SMTP settings configured in
  # config/environments/development.rb. See app/services/real_email_toggle.rb
  # and the banner in app/views/shared/_dev_mail_banner.html.erb.
  class DevelopmentMailInterceptor
    MAILPIT_SETTINGS = { address: "localhost", port: 1025 }.freeze

    def self.delivering_email(message)
      return if RealEmailToggle.enabled?

      message.delivery_method.settings = MAILPIT_SETTINGS
    end
  end

  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
end
