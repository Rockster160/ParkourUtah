Rails.application.routes.draw do

  root 'index#index'
  post '/contact' => 'index#contact'

  get '/class/:id' => 'peeps#pin_user', as: 'begin_class'
  get '/pin/:id' => 'peeps#show_user'
  put '/password/:id' => 'peeps#pin_password'
  patch '/charge_class/:id' => 'peeps#validate_pin'

  get '/athletes/new' => 'dependents#new', as: 'new_athlete'
  post '/athletes/create' => 'dependents#create'
  post '/athletes/update/:athlete_id' => 'dependents#update'

  get '/waiver/:athlete_id' => 'dependents#waiver', as: 'sign_waiver'
  post '/waiver/sign' => 'dependents#sign_waiver'

  devise_for :users do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  get 'calendar/index' => 'calendar#index', as: 'calendar'
  get 'calendar/draw' => 'calendar#draw', as: 'calendar_draw'

  get 'schedule/:location' => 'calendar#show', as: 'calendar_show'

  get 'events/new' => 'event#new', as: 'add_event'
  post 'events/create' => 'event#create'
  delete 'events/destroy' => 'event#destroy', as: 'destroy_event'
  post 'events/subscribe/:id' => 'event#subscribe', as: 'subscribe'
  delete 'events/unsubscribe/:id' => 'event#unsubscribe', as: 'unsubscribe'

  get '/dashboard' => 'peeps#dashboard', as: 'dashboard'
  get '/peeps/return' => 'peeps#return'

  get '/comingsoon' => 'index#coming_soon', as: 'coming_soon'

  get '/store' => 'store#index', as: 'store'
  post '/store' => 'store#redeem'
  get '/store/new' => 'store#new', as: 'add_item'
  get '/store/edit/:id' => 'store#edit', as: 'edit_item'
  patch '/store/update/:id' => 'store#update'
  post '/store/create' => 'store#create'

  get '/store/admin/generate_keys' => 'store#generate_keys', as: 'generate_keys'
  post '/store/admin/generate_keys' => 'store#email_keys'

  post '/cart/update' => 'store#update_cart', as: 'update_cart'
  post '/cart/purchase' => 'store#purchase', as: 'purchase'

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.is_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

end
