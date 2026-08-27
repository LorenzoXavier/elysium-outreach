Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    post "dev/mail_toggle", to: "dev/mail_toggles#update", as: :dev_mail_toggle
  end

  root "dashboard#index"

  get "archive", to: "archive#index"

  resources :duplicates, only: [ :index ] do
    member do
      post :confirm
      post :mark_unique
    end
  end

  resources :imports, only: [ :new, :create ]

  resources :email_templates do
    collection do
      post :ai_draft
    end
  end

  resources :scheduled_emails, only: [ :index ] do
    member do
      post :cancel
    end
  end

  resources :contacts, only: [ :show, :new, :create, :edit, :update ] do
    member do
      patch :update_priority
      patch :mark_linkedin_outreached
      get :edit_email
      patch :update_email
      post :publish_email

      get :new_scheduled_email
      post :schedule_email
      post :send_email_now

      get :new_linkedin_message
      post :generate_linkedin_message
      post :save_linkedin_message
    end

    collection do
      post :bulk_mark_linkedin_outreached
    end
  end
end
