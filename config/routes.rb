ActionController::Routing::Routes.draw do |map|


  Blacklight::Routes.build map



  map.fedora_metadata_pretty '/download/fedora_metadata_pretty/:id', :controller => 'download', :action => 'fedora_metadata_pretty'
  map.fedora_content '/download/fedora_content/:download_method/:uri/:filename', :controller => 'download', :action => 'fedora_content',
    :uri => /.+/, :filename => /.+/, :download_method => /(download|show)/
  map.wind_logout '/wind_logout', :controller => 'welcome', :action => 'logout'
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
