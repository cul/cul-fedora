ActionController::Routing::Routes.draw do |map|
  map.resources :reports




  Blacklight::Routes.build map


  map.fedora_content '/download/fedora_content/:download_method/:uri/:block/:filename', 
    :controller => 'download', :action => 'fedora_content',
    :block => /(DC|CONTENT|SOURCE)/,
    :uri => /.+/, :filename => /.+/, :download_method => /(download|show|show_pretty)/
  map.cachecontent '/download/cache/:download_method/:uri/:block/:filename', 
    :controller => 'download', :action => 'cachecontent',
    :block => /(DC|CONTENT|SOURCE)/,
    :uri => /.+/, :filename => /.+/, :download_method => /(download|show|show_pretty)/
  map.wind_logout '/wind_logout', :controller => 'welcome', :action => 'logout'
  map.access_denied '/access_denied', :controller => 'welcome', :action => 'access_denied'
  map.thumbnail '/thumbnail/:id', :controller => 'thumbnail', :action => 'get'

#  map.resource :folder
#  map.connect '/folder/destroy', :controller => 'folder', :action => 'destroy', 
#    :category => /(by_collection)/
  
  map.resource :report
  
  map.connect '/reports/preview/:category', :controller => 'reports', :action => 'preview', 
    :category => /(by_collection)/
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end
