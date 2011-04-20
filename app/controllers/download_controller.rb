require 'net/http'
class DownloadController < ApplicationController
  before_filter :require_staff
  filter_access_to :fedora_content, :attribute_check => true,
                   :model => nil, :load_method => :download_from_params
  caches_action :cachecontent, :expires_in => 7.days,
    :cache_path => proc { |c|
      c.params
    }
  def cachecontent
    url = FEDORA_CONFIG[:riurl] + "/get/" + params[:uri]+ "/" + params[:block]

    cl = http_client
    h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    h_ct = cl.head(url).header["Content-Type"].to_s
    headers.delete "Cache-Control"
    headers["Content-Disposition"] = h_cd
    headers["Content-Type"] = h_ct
    
    render :status => 200, :text => cl.get_content(url)
  end
  def download_from_params
    unless defined?(@download)
      pid = params[:uri]
      ds = params[:block]
      r_obj = Cul::Fedora::Objects::BaseObject.new({:pid_s => pid},http_client)
      triples = r_obj.triples
      @download = DownloadObject.new
      triples.each { |triple|
        predicate = triple["predicate"]
        if predicate.eql? "http://purl.org/dc/elements/1.1/format"
          @download.mime_type=triple["object"]
        elsif predicate.eql? "info:fedora/fedora-system:def/model#hasModel"
          @download.content_models.push(triple["object"])
        end
      }
    end
    params[:object] = @download
  end
  def fedora_content
      
    url = FEDORA_CONFIG[:riurl] + "/get/" + params[:uri]+ "/" + params[:block]

    cl = http_client
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

      # Chunking would be preferred, but not working with basic auth
      # Neither setting header nor included .set_auth method works
      # rhdrs = {'Authorization' => fedora_creds}
      # render :status => 200, :text => Proc.new { |response, output|
        #cl.get_content(url,:query =>nil,:header =>rhdrs) do |chunk|
        #  output.write chunk
        #end
      # }
      uri = URI.parse(url)
      cl = Net::HTTP.new(uri.host,uri.port)
      cl.use_ssl = (uri.scheme == 'https')
      cl.verify_mode = OpenSSL::SSL::VERIFY_NONE
      cl.start { |http|
        req = Net::HTTP::Get.new(uri.path)
        req.basic_auth FEDORA_CREDENTIALS_CONFIG[:username], FEDORA_CREDENTIALS_CONFIG[:password]
        response = http.request(req)
        render :status=>response.code, :text=>response.body
      }
    end
  end

  class DownloadObject
    attr_reader :content_models, :mime_type
    attr_writer :mime_type
    def initialize ()
      @content_models = []
      @mime_type = nil
    end
  end
end


