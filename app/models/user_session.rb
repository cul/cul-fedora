class UserSession < Authlogic::Session::Base 
  unloadable
  wind_host "wind.columbia.edu"
  wind_service "culscv"
  auto_register true
  auto_provision ["ldpd.cunix.local:columbia.edu"]
  login_only_with_wind true

end
