class DownloadController < ApplicationController
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
      if h_ct.include?("xml")
        
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


