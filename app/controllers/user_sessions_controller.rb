class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
    params[:login_with_wind] = true if UserSession.login_only_with_wind
    session[:return_to] = params[:return_to] if params[:return_to]
    @user_session.save 
  end
  
end
