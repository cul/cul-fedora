require_dependency 'vendor/plugins/blacklight/app/controllers/application_controller.rb' 
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  unloadable
  helper :all # include all helpers, all the time

  protected

  def require_user
    unless current_user
      store_location
      redirect_to new_user_session_url
      return false
    end
  end

  def require_admin
    if current_user
      unless current_user.admin
        redirect_to access_denied_url  
      end
    else
      store_location
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def openlayers_base
   @olbase ||= 'http://www.columbia.edu/cu/libraries/inside/projects/imaging/jsonp-openlayers'
  end
  def openlayers_js 
   @oljs ||= openlayers_base + '/lib/OpenLayers.js'
  end
  def openlayers_css
   @olcss ||= openlayers_base + '/theme/default/style.css'
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  def javascript_tag(href)
    '<script src="' + href + '" type="text/javascript"></script>'
  end
  def stylesheet_tag(href, args)
    '<link href="' + href + '" rel="stylesheet" type="text/css" media="' + args[:media] + '" />'
  end
  def default_html_head
    stylesheet_links << ['yui', 'jquery/ui-lightness/jquery-ui-1.8.1.custom.css', 'application',{:plugin=>:blacklight, :media=>'all'}]
    stylesheet_links << ['zooming_image', 'accordion', {:media=>'all'}]
    stylesheet_links << ['application']
    stylesheet_links << ['scv']
    javascript_includes << ['jquery-1.4.2.min.js', 'jquery-ui-1.8.1.custom.min.js', 'blacklight', 'application', { :plugin=>:blacklight } ]
    javascript_includes << ['accordion', 'zooming_image']
    extra_head_content << [stylesheet_tag(openlayers_css, :media=>'all'), javascript_tag(openlayers_js)]
  end

end
