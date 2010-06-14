class DownloadController < ApplicationController
  def fedora_content

    headers["Content-Type"] = determine_content_type
    headers["Content-Disposition"] = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    

    url = FEDORA_CONFIG[:riurl] + "/get/" + params[:uri]+ "/CONTENT"
    
    cl = HTTPClient.new

    render :status => 200, :text => Proc.new { |response, output|
      cl = HTTPClient.new

      cl.get_content(url) do |chunk|
        output.write chunk
      end
    }
  end

  private

  def determine_content_type
    return params[:type] if params[:type]
    
    filename = params[:filename].downcase.to_s
    if filename.include?(".xml")
      "application/xml"
    end
  end
end


