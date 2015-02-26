Rails.application.routes.draw do

  root 'index#index'
  get '/secret' => 'peeps#secret'
  patch '/secrets' => 'peeps#secret_submit'

  devise_for :users do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  get 'calendar/index' => 'calendar#index', as: 'calendar'
  get 'calendar/day/:date' => 'calendar#day', as: 'calendar_day'
  get 'calendar/draw' => 'calendar#draw', as: 'calendar_draw'

  get 'schedule/:location' => 'calendar#show', as: 'calendar_show'

  get 'events/show/:id' => 'event#show', as: 'event'
  get 'events/new' => 'event#new', as: 'add_event'
  post 'events/create' => 'event#create'
  delete 'events/destroy' => 'event#destroy', as: 'destroy_event'

  get 'peeps/show/:id' => 'peeps#show', as: 'peep_show'

  get '/store' => 'store#index', as: 'store'
  get '/store/new' => 'store#new', as: 'add_item'
  get '/store/edit/:id' => 'store#edit', as: 'edit_item'
  patch '/store/update/:id' => 'store#update'
  post '/store/create' => 'store#create'

  get '/cart/add/:id' => 'store#add_to_cart', as: 'add_to_cart'
  get '/cart/show' => 'store#show_cart', as: 'show_cart'
  post '/cart/update' => 'store#update_cart', as: 'update_cart'
end
