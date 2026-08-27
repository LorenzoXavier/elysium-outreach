Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  get "archive", to: "archive#index"

  resources :duplicates, only: [:index] do
    member do
      post :confirm
      post :mark_unique
    end
  end

  resources :imports, only: [:new, :create]

  resources :contacts, only: [:show, :edit, :update] do
    member do
      patch :update_priority
      patch :mark_linkedin_outreached
      get :edit_email
      patch :update_email
      post :publish_email
    end

    collection do
      post :bulk_mark_linkedin_outreached
    end
  end
end
