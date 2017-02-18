Rails.application.routes.draw do

  root 'index#index'

  match '404', to: 'index#page_not_found', via: :all
  match '422', to: 'index#page_not_found', via: :all
  match '500', to: 'index#page_broken', via: :all

  get 'talk' => 'index#get_request'
  post 'listen' => 'index#give_request'

  get 'register/step_2' => 'registrations#step_2', as: 'step_2'
  get 'register/step_3' => 'registrations#step_3', as: 'step_3'
  get 'register/step_4' => 'registrations#step_4', as: 'step_4'
  get 'register/step_5' => 'registrations#step_5', as: 'step_5'
  post 'register/step_2' => 'registrations#post_step_2'
  post 'register/step_3' => 'registrations#post_step_3'
  post 'register/step_4' => 'registrations#post_step_4'
  post 'register/step_4/fix' => 'registrations#fix_step_4', as: 'fix_review_page'
  post 'register/step_5' => 'registrations#post_step_5'

  resources :instructors do
    member do
      post :update_position
    end
  end

  resources :spots
  resources :events, only: [ :show, :edit, :update ] do
    member do
      post :cancel
      get :detail
    end
  end
  resources :event_schedules, except: [ :destroy ] do
    member do
      post :subscribe
      delete :unsubscribe
      post :send_message_to_subscribers
    end
  end

  resources :line_items, except: [ :show ] do
    member do
      put :update_position
    end
  end

  resources :redemption_keys, except: [ :show, :edit, :update, :destroy ] do
    member do
      get :redeem
    end
  end

  resources :class_handlers, path: 'class', only: [] do
    member do
      get :athlete_id
      get :athlete_pin
      get :logs
      post :join_class
    end
  end

  resources :attendances, only: [ :index ]
  resources :aws_loggers, only: [ :index, :show ]
  resources :contact_requests, only: [ :index, :show ]
  resources :messages, only: [ :show, :create ]

  get :dashboard, controller: :admins
  resource :admin, only: [] do
    get :purchase_history
    get :summary

    get :batch_text_message
    post :send_batch_texts

    get :email_body
    get :batch_email
    post :send_batch_emailer
  end
  resources :admin_users, path: "admin/users", only: [ :show, :index, :destroy ] do
    member do
      get :attendance
      post :update_trials
      post :update_credits
      post :update_notifications

    end
  end

  post 'contact' => 'index#contact'
  post 'receive_sms' => 'index#receive_sms'
  get 'contact' => 'index#contact_page', as: 'contact_page'
  post 'update' => 'index#update'
  get 'unsubscribe' => 'index#unsubscribe', as: 'unsubscribe_email'
  post 'sms_receivable' => 'index#sms_receivable', as: 'make_sms_receivable'

  delete 'unsubscribe_monthly/:id' => 'store#unsubscribe', as: 'unsubscribe_monthly_subscription'

  get 'athletes/new' => 'dependents#new', as: 'new_athlete'
  post 'athletes/new' => 'dependents#create'
  # post 'athletes/create' => 'dependents#create'
  post 'athletes/update/:athlete_id' => 'dependents#update'
  post 'athletes/reset/:athlete_id' => 'dependents#reset_pin', as: 'reset_pin'
  delete 'athlete/:id/delete' => 'dependents#destroy', as: 'destroy_athlete'
  post 'athletes/verify' => 'dependents#verify', as: 'verify_athletes'
  post 'athletes/assign_subscription/:athlete_id' => 'dependents#assign_subscription', as: 'assign_subscription'
  patch 'athletes/update_photo/:id' => 'dependents#update_photo'

  get 'waivers' => 'dependents#sign_waiver', as: 'waivers'
  post 'waivers' => 'dependents#update_waiver'
  post 'delete_athlete/:athlete_id' => 'dependents#delete_athlete'

  get "users/sign_up", action: "new", controller: "users"
  get "users/edit", action: "edit", controller: "users"
  get "users/edit", action: "edit", controller: "users"
  resource :user, except: [ :show ]
  devise_for :users
  devise_scope :user do
    get "/account" => "users/registrations#edit"
  end
  post 'user/notifications/update' => 'index#update_notifications'

  get "/calendar/all", to: redirect("/calendar")
  get 'calendar' => 'calendar#show', as: 'calendar_show'
  get 'calendar/week' => 'calendar#get_week', as: 'week'
  get 'm/calendar' => 'calendar#mobile', as: 'calendar_mobile'
  get 'calendar/:city' => 'calendar#show'

  post 'store/charge' => 'store#charge', as: 'charge'
  get 'store' => 'store#index', as: 'store'
  post 'store/redeem' => 'store#redeem'

  post 'cart/update' => 'store#update_cart', as: 'update_cart'
  post 'cart/purchase' => 'store#purchase', as: 'purchase'

  namespace :api do
    namespace :v1 do
      post :valid_credentials
      get :valid_credentials
    end
  end

  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => 'sidekiq'
  end

end
