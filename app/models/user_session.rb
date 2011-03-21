class UserSession < Authlogic::Session::Base 
  unloadable
  
  wind_host "wind.columbia.edu"
  wind_service "culscv"
  auto_register true
  login_only_with_wind true

end
