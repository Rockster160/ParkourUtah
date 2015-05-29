Rails.application.routes.draw do

  root 'index#index'

  match '/404', to: 'index#page_not_found', via: :all
  match '/422', to: 'index#page_not_found', via: :all
  match '/500', to: 'index#page_broken', via: :all

  get '/talk' => 'index#get_request'
  post '/listen' => 'index#give_request'
  get '/secret' => 'peeps#secret', as: 'secret'
  post '/post_secret' => 'peeps#post_secret'

  get '/register/step_2' => 'registrations#step_2', as: 'step_2'
  get '/register/step_3' => 'registrations#step_3', as: 'step_3'
  get '/register/step_4' => 'registrations#step_4', as: 'step_4'
  get '/register/step_5' => 'registrations#step_5', as: 'step_5'
  post '/register/step_2' => 'registrations#post_step_2'
  post '/register/step_3' => 'registrations#post_step_3'
  post '/register/step_4' => 'registrations#post_step_4'
  post '/register/step_4/fix' => 'registrations#fix_step_4', as: 'fix_review_page'
  post '/register/step_5' => 'registrations#post_step_5'

  get '/test' => 'index#index'
  post '/contact' => 'index#contact'
  post '/receive_sms' => 'index#receive_sms'
  get '/contact' => 'index#contact_page', as: 'contact_page'
  post '/update' => 'index#update'
  get '/unsubscribe' => 'index#unsubscribe', as: 'unsubscribe_email'

  get '/class/:id' => 'peeps#pin_user', as: 'begin_class'
  get '/pin/:id' => 'peeps#show_user'
  get '/logs/:id' => 'peeps#class_logs', as: 'class_logs'
  put '/password/:id' => 'peeps#pin_password'
  patch '/charge_class/:id' => 'peeps#validate_pin'

  get '/peeps/edit' => 'peeps#edit', as: 'edit_peeps'
  get '/peeps/edit_peep/:id' => 'peeps#edit_peep', as: 'edit_peep'
  put '/peeps/update_position/:id' => 'peeps#update_peep_position', as: 'update_peep_position'
  patch '/peeps/update/:id' => 'peeps#update', as: 'update_peep'
  get '/peeps/promote' => 'peeps#promote', as: 'promote'
  post '/peeps/promote' => 'peeps#promotion', as: 'promotion'
  post '/peeps/demotion/:id' => 'peeps#demotion', as: 'demotion'
  get '/peeps/users' => 'peeps#recent_users', as: 'recent_users'
  post '/peeps/users' => 'peeps#adjust_credits'
  delete '/user/:id' => 'peeps#destroy_user', as: 'user'
  delete 'unsubscribe_monthly/:id' => 'store#unsubscribe', as: 'unsubscribe_monthly_subscription'

  get '/athletes/new' => 'dependents#new', as: 'new_athlete'
  post '/athletes/new' => 'dependents#create'
  # post '/athletes/create' => 'dependents#create'
  post '/athletes/update/:athlete_id' => 'dependents#update'
  post '/athletes/forgot/:athlete_id' => 'dependents#forgot_pin_or_id', as: 'send_reset_pin_or_id_mail'
  get '/athletes/reset/:athlete_id' => 'dependents#reset_pin', as: 'reset_athlete_pin'
  delete '/athlete/:id/delete' => 'dependents#destroy', as: 'destroy_athlete'
  post '/athletes/verify' => 'dependents#verify', as: 'verify_athletes'

  get '/waivers' => 'dependents#sign_waiver', as: 'waivers'
  post '/waivers' => 'dependents#update_waiver'
  post '/delete_athlete/:athlete_id' => 'dependents#delete_athlete'

  devise_for :users, :controllers => {:registrations => "users/registrations"}
  post '/user/notifications/update' => 'index#update_notifications'

  get 'calendar/index' => 'calendar#index', as: 'calendar'
  get 'calendar/draw' => 'calendar#draw', as: 'calendar_draw'

  get 'schedule/:location' => 'calendar#show', as: 'calendar_show'

  get 'events/new' => 'event#new', as: 'add_event'
  post 'events/create' => 'event#create'
  get 'events/edit/:id' => 'event#edit', as: 'edit_event'

  get 'events/cities' => 'event#cities', as: 'cities'
  get 'events/cities/:city' => 'event#city', as: 'city'
  post 'events/cities/:city/:color' => 'event#color_city', as: 'color_city'

  patch 'events/update/:id' => 'event#update'
  delete 'events/destroy' => 'event#destroy', as: 'destroy_event'
  post 'events/subscribe/:id' => 'event#subscribe', as: 'subscribe'
  delete 'events/unsubscribe/:id' => 'event#unsubscribe', as: 'unsubscribe'

  get '/dashboard' => 'peeps#dashboard', as: 'dashboard'
  get '/peeps/return' => 'peeps#return'

  get '/comingsoon' => 'index#coming_soon', as: 'coming_soon'

  post '/store/charge' => 'store#charge', as: 'charge'
  get '/store' => 'store#index', as: 'store'
  post '/store/redeem' => 'store#redeem'
  get '/store/new' => 'store#new', as: 'add_item'
  get '/store/edit/:id' => 'store#edit', as: 'edit_item'
  get '/store/index' => 'store#items', as: 'edit_items'
  patch '/store/update/:id' => 'store#update'
  post '/store/create' => 'store#create'
  delete '/store/item/:id/destroy' => 'store#destroy', as: 'destroy_item'
  put '/store/update_position/:id' => 'store#update_item_position', as: 'update_item_position'

  get '/store/admin/generate_keys' => 'store#generate_keys', as: 'generate_keys'
  post '/store/admin/generate_keys' => 'store#email_keys'

  post '/cart/update' => 'store#update_cart', as: 'update_cart'
  post '/cart/purchase' => 'store#purchase', as: 'purchase'

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

end
