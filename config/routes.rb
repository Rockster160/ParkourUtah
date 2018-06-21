Rails.application.routes.draw do

  root 'index#index'

  match '404', to: 'index#page_not_found', via: :all
  match '422', to: 'index#page_not_found', via: :all
  match '500', to: 'index#page_broken', via: :all

  get :faq, to: "index#faq"

  get :flash_message, controller: "application"

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

  # Websockets
  mount ActionCable.server => '/cable'

  resources :instructors do
    member do
      post :update_position
    end
  end

  resources :competitions, only: [:index, :show] do
    get :monitor
    get :judge
    get "judge/:category",              action: :category, as: :category
    get "judge/:category/:competitor_id",  action: :competitor, as: :competitor
    post "judge/:category/:competitor_id", action: :judge_competitor, as: :judge_competitor
  end
  resources :competitors, only: [:create, :update] do
    get :complete, on: :member
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

  resources :redemption_keys, except: [ :show, :edit, :update ] do
    member do
      get :redeem
    end
  end

  resources :class_handlers, path: 'class', only: [] do
    member do
      get :fast_pass_id
      get :fast_pass_pin
      get :logs
      post :join_class
    end
  end

  resources :announcements, except: [ :show ] do
    post :view, on: :collection
    post :deliver, on: :member
  end

  resources :attendances, only: [ :index, :new, :create, :destroy ]
  resources :aws_loggers, only: [ :index, :show ]
  resources :log_trackers, only: [ :index, :show ]
  resources :contact_requests, only: [ :index, :show ]
  resources :chat_rooms, path: "chat", only: [ :index, :show ] do
    get "phone_number/:phone_number", on: :collection, action: :by_phone_number, as: :phone_number
    post 'all/mark_messages_as_read', on: :collection, action: :mark_messages_as_read, as: :mark_messages_as_read
    resources :messages, only: [ :index ] do
      post :mark_messages_as_read, on: :collection
    end
  end

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
  post 'unsubscribe' => 'index#unsubscribe_email', as: :unsubscribe
  post 'can_receive_sms' => 'index#can_receive_sms', as: 'make_can_receive_sms'

  delete 'unsubscribe_monthly/:id' => 'store#unsubscribe', as: 'unsubscribe_monthly_subscription'

  resources :athletes do
    member do
      post :reset_pin
    end
    collection do
      post :verify
      post :assign_subscription
      patch :update_photo
    end
  end

  get 'waivers' => 'athletes#sign_waiver', as: 'waivers'
  post 'waivers' => 'athletes#update_waiver'
  post 'delete_athlete/:fast_pass_id' => 'athletes#delete_athlete'

  get "users/sign_up", action: "new", controller: "users"
  get "users/edit", action: "edit", controller: "users"
  get "users/edit", action: "edit", controller: "users"
  resource :user, except: [ :show ] do
    post :update_card_details
  end
  devise_for :users
  devise_scope :user do
    get "/account" => "users#edit"
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
      resources :users
    end
  end

  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => 'sidekiq'
  end

end
