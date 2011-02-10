class DownloadController < ApplicationController
  after_filter :remove_session, :only => :cache
  def cache
    url = FEDORA_CONFIG[:riurl] + "/get/" + params[:uri]+ "/" + params[:block]

    cl = HTTPClient.new
    h_resp = cl.head(url)
    h_resp.header.all.each do |k,v|
      response.headers[k] = v
    end
    if request.head?
      render :status => 200, :text => ''
      return
    end
    h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
 
    response.headers["Content-Disposition"] = h_cd unless response.headers["Content-Disposition"]
    response.headers["Cache-Control"] =  "public, max-age=86400" # one day
    _expiry = Time.now + 86400 # expire tomorrow
    response.headers["Expires"] =  _expiry.strftime("%a, %d %b %Y %H:%M:%S %Z")
    render :status => 200, :text => Proc.new { |response, output|
      cl.get_content(url) do |chunk|
        output.write chunk
      end
    }
  end
  def remove_session
    cookies.each do |cookie|
      puts cookie
    end
    # cookies.delete :"_blacklight-app_session"
    response.headers.each do |header|
      puts header
    end
    response.headers["Set-Cookie"] = nil;
  end
  def fedora_content
      
    url = FEDORA_CONFIG[:riurl] + "/get/" + params[:uri]+ "/" + params[:block]

    cl = HTTPClient.new
    h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    h_ct = cl.head(url).header["Content-Type"].to_s
    text_result = nil

    case params[:download_method]
    when "download"
      h_cd = "attachment; " + h_cd 
    when "show_pretty"
      if h_ct.include?("xml") || params[:print_binary_octet]
        
        xsl = Nokogiri::XSLT(File.read(RAILS_ROOT + "/app/stylesheets/pretty-print.xsl"))
        xml = Nokogiri(cl.get_content(url))
        text_result = xsl.apply_to(xml).to_s
      else
        text_result = "Non-xml content streams cannot be pretty printed."
      end
    end

    if text_result
      headers["Content-Type"] = "text/plain"
      render :text => text_result
    else
        
      headers["Content-Disposition"] = h_cd
      headers["Content-Type"] = h_ct

      
      render :status => 200, :text => Proc.new { |response, output|
        cl.get_content(url) do |chunk|
          output.write chunk
        end
      }
    end
  end

end


