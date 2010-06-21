ActionController::Routing::Routes.draw do |map|


  Blacklight::Routes.build map


  map.fedora_content '/download/fedora_content/:download_method/:uri/:block/:filename', 
    :controller => 'download', :action => 'fedora_content',
    :block => /(DC|CONTENT)/,
    :uri => /.+/, :filename => /.+/, :download_method => /(download|show|show_pretty)/
  map.wind_logout '/wind_logout', :controller => 'welcome', :action => 'logout'
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
