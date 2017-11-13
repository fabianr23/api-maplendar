Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post '/sign-in', to: 'authenticate#authUser'
  get '/logout', to: 'authenticate#logout'
  
  post '/events/', to: 'manage_events#createEvent'
  post '/events/:event_id/invite', to: 'manage_events#inviteUsers'
  get '/events/', to: 'manage_events#getEvents'
  get '/events/:event_id/attendance', to: 'manage_events#getEventWithAttendance'
  get '/events/myEvents', to: 'manage_events#getMyEvents'
  get '/events/site/:site_id', to: 'manage_events#getEventsBySite'
  
  

  get '/sites', to: 'manage_events#getSites'

  post '/users/', to: 'manage_users#createUser'
  get '/users/myProfile', to: 'manage_users#profile'  
  put '/users/update/:id', to: 'manage_users#updateUser'
  get '/users/search', to: 'manage_users#searchUsers'


  put '/events/:event_id/attendance', to: 'manage_events#defineAttendance'  

end
