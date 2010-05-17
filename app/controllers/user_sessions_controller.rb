class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
    params[:login_with_wind] = true if UserSession.login_only_with_wind
    session[:return_to] = params[:return_to] if params[:return_to]
    @user_session.save 
  end
  
  
  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|  
      if result  
        session[:return_to] = nil if session[:return_to].to_s.include?("logout")
        redirect_back_or_default root_url  
      else  
        flash[:error] = "Unsuccessfully logged in."
        redirect_to root_url
      end  
    end
    
  end
  
  def destroy
    current_user_session.destroy
    redirect_to wind_logout_url
  end
end
