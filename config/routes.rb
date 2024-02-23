Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  namespace :api, defaults: { format: 'json' } do
    get '/products/search', to: 'products#search'
    get '/products/approval-queue', to: 'products#approval_queue'
    put '/products/approval-queue/:approvalId/approve', to: 'products#approve'
    put '/products/approval-queue/:approvalId/reject', to: 'products#reject'
    resources :products
  end
end
