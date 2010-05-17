ActionController::Routing::Routes.draw do |map|


  Blacklight::Routes.build map



  map.wind_logout '/wind_logout', :controller => 'welcome', :action => 'logout'
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
