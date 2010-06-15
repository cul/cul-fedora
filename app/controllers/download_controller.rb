class DownloadController < ApplicationController
  def fedora_content

    cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    cd = "attachment; " + cd if params[:download_method] == "download"
    
    headers["Content-Disposition"] = cd


    url = FEDORA_CONFIG[:riurl] + "/get/" + params[:uri]+ "/CONTENT"
    
    cl = HTTPClient.new
    headers["Content-Type"] = cl.head(url).header["Content-Type"].to_s
  
    render :status => 200, :text => Proc.new { |response, output|
      cl.get_content(url) do |chunk|
        output.write chunk
      end
    }
  end

  def fedora_metadata_pretty
    
  end
  private

end


