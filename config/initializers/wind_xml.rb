AuthlogicWind::Session::Methods.module_eval do
  def generate_verified_login
    validate_path = "/validate?ticketid=#{wind_controller.params['ticketid']}"
    wind_validate = Net::HTTP.new("wind.columbia.edu",443)
    wind_validate.use_ssl = true
    wind_validate.start
    wind_resp = wind_validate.get(validate_path)
    wind_validate.finish
    puts wind_resp.body
    authdoc = Nokogiri::XML(wind_resp.body)
    ns = {'wind'=>'http://www.columbia.edu/acis/rad/authmethods/wind'}
    _user = authdoc.xpath('//wind:authenticationSuccess/wind:user', ns)
    if _user.length > 0
      return _user[0].content
    else
      nil
    end
  end
end
