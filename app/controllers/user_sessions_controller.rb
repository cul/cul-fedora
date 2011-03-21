class UserSessionsController < ApplicationController
  unloadable
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    current_user_session.destroy if current_user_session
    @user_session = UserSession.new
    params[:login_with_wind] = true if UserSession.login_only_with_wind
    session[:return_to] = params[:return_to] || root_url
    @user_session.save 
  end

 
  def create
    params.each { |k,v| puts "#{k}: #{v}" }
    validate_path = "/validate?ticketid=#{params['ticketid']}"
    wind_validate = Net::HTTP.new("wind.columbia.edu",443)
    wind_validate.use_ssl = true
    wind_validate.start
    wind_resp = wind_validate.get(validate_path)
    wind_validate.finish
    puts wind_resp.body
    authdoc = Nokogiri::XML(wind_resp.body)
    ns = {'wind'=>'http://www.columbia.edu/acis/rad/authmethods/wind'}
    af = authdoc.xpath('//wind:authenticationFailure', ns)
    if af.length > 0
      flash[:error] = "Unsuccessfully logged in."
      redirect_to wind_logout_url
      return
    else
      puts "No auth failure found"
    end
    uni = authdoc.xpath('//wind:user', ns)[0].content
    @user_session = UserSession.new(uni)
    @user_session.save do |result|  
      if result  
        session[:return_to] = nil if session[:return_to].to_s.include?("logout")
        redirect_back_or_default root_url  
      else  
        flash[:error] = "Unsuccessfully logged in."
        redirect_to wind_logout_url
        return
      end  
    end
    
  end
  
  def destroy
    current_user_session.destroy
    redirect_to wind_logout_url
  end
end
