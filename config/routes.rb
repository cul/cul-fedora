ActionController::Routing::Routes.draw do |map|


  Blacklight::Routes.build map


  map.fedora_content '/download/fedora_content/:download_method/:uri/:block/:filename', 
    :controller => 'download', :action => 'fedora_content',
    :block => /(DC|CONTENT|SOURCE)/,
    :uri => /.+/, :filename => /.+/, :download_method => /(download|show|show_pretty)/
  map.wind_logout '/wind_logout', :controller => 'welcome', :action => 'logout'
  map.access_denied '/access_denied', :controller => 'welcome', :action => 'access_denied'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end
