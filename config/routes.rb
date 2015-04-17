Rails.application.routes.draw do

  root 'index#index'
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

  get '/athletes/new' => 'dependents#new', as: 'new_athlete'
  post '/athletes/new' => 'dependents#create'
  # post '/athletes/create' => 'dependents#create'
  post '/athletes/update/:athlete_id' => 'dependents#update'
  post '/athletes/forgot/:athlete_id' => 'dependents#forgot_pin_or_id', as: 'send_reset_pin_or_id_mail'
  get '/athletes/reset/:athlete_id' => 'dependents#reset_pin', as: 'reset_athlete_pin'

  get '/waivers' => 'dependents#waivers', as: 'waivers'
  post '/waivers' => 'dependents#sign_waiver'

  devise_for :users do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  get 'calendar/index' => 'calendar#index', as: 'calendar'
  get 'calendar/draw' => 'calendar#draw', as: 'calendar_draw'

  get 'schedule/:location' => 'calendar#show', as: 'calendar_show'

  get 'events/new' => 'event#new', as: 'add_event'
  post 'events/create' => 'event#create'
  get 'events/edit/:id' => 'event#edit', as: 'edit_event'

  get 'events/index' => 'event#index', as: 'edit_events'
  post 'events/update/:token' => 'event#update_token', as: 'update_colors'

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
