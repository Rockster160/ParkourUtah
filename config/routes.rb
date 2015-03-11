Rails.application.routes.draw do

  root 'index#index'

  get '/athlete' => 'peeps#pin_user', as: 'enter_pin'
  get '/pin' => 'peeps#show_user'
  get '/password' => 'peeps#pin_password'
  patch '/charge_class' => 'peeps#charge_class'

  get '/athletes/new' => 'dependents#new', as: 'new_athlete'
  post '/athletes/create' => 'dependents#create'
  get '/waiver/:athlete_id' => 'dependents#waiver', as: 'sign_waiver'
  post '/waiver/sign' => 'dependents#sign_waiver'

  devise_for :users do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  get 'calendar/index' => 'calendar#index', as: 'calendar'
  # get 'calendar/day/:date' => 'calendar#day', as: 'calendar_day'
  get 'calendar/draw' => 'calendar#draw', as: 'calendar_draw'

  get 'schedule/:location' => 'calendar#show', as: 'calendar_show'

  # get 'events/show/:id' => 'event#show', as: 'event'
  get 'events/new' => 'event#new', as: 'add_event'
  post 'events/create' => 'event#create'
  delete 'events/destroy' => 'event#destroy', as: 'destroy_event'

  # get 'peeps/show/:id' => 'peeps#show', as: 'peep_show'
  # get '/dashboard' => 'peeps#dashboard', as: 'dashboard'
  get '/peeps/return' => 'peeps#return'

  # get '/store' => 'index#coming_soon'
  # get '/store/new' => 'index#coming_soon'
  # get '/store/edit/:id' => 'index#coming_soon'
  # patch '/store/update/:id' => 'index#coming_soon'
  # post '/store/create' => 'index#coming_soon'

  get '/store' => 'store#index', as: 'store'
  get '/store/new' => 'store#new', as: 'add_item'
  get '/store/edit/:id' => 'store#edit', as: 'edit_item'
  patch '/store/update/:id' => 'store#update'
  post '/store/create' => 'store#create'

  get '/cart/add/:id' => 'store#add_to_cart', as: 'add_to_cart'
  get '/cart/show' => 'store#show_cart', as: 'show_cart'
  post '/cart/update' => 'store#update_cart', as: 'update_cart'
  post '/cart/purchase' => 'store#purchase', as: 'purchase'

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

end
