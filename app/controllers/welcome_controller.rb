require 'uri'
class WelcomeController < ApplicationController

  def logout
    dest = url_for(:controller => 'catalog', :action => 'index')
    dest = URI.escape(dest)
    text = 'Return%20to%20SCV'
    _logout = "https://wind.columbia.edu/logout?destination=#{dest}&destinationtext=#{text}"
    redirect_to _logout
  end
end
