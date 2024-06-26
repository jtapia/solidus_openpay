# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  namespace :openpay do
    resources :payments, only: [:create, :show]
  end
end
