eval File.read('vendor/plugins/blacklight/app/controllers/application_controller.rb')
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  protect_from_forgery # See ActionController::RequestForgeryProtection for details

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
    stylesheet_links << ['zooming_image', {:media=>'all'}]
    javascript_includes << ['jquery-1.4.2.min.js', 'jquery-ui-1.8.1.custom.min.js', 'blacklight', 'application', { :plugin=>:blacklight } ]
    javascript_includes << ['accordion_local', 'zooming_image']
    extra_head_content << [stylesheet_tag(openlayers_css, :media=>'all'), javascript_tag(openlayers_js)]
  end

end
