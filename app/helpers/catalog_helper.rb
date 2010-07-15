module CatalogHelper


  def build_resource_list(document)
    obj_display = (document["object_display"] || []).first
    results = []
    case document["format"]
    when "image/zooming"
      base_id = base_id_for(document)
      url = FEDORA_CONFIG[:riurl] + "/get/" + base_id + "/SOURCE"
      head_req = HTTPClient.new.head(url)
      # raise head_req.inspect
      file_size = head_req.header["Content-Length"].first.to_i
      results << {:dimensions => "Original", :mime_type => "image/jp2", :show_path => fedora_content_path("show", base_id, "SOURCE", base_id + "_source.jp2"), :download_path => fedora_content_path("download", base_id , "SOURCE", base_id + "_source.jp2")}  
    when "image"
      if obj_display
        images = doc_json_method(document, "/ldpd:sdef.Aggregator/listMembers?max=&format=json&start=&callback=?")["results"]
        images.each do |image|
          res = {}
          res[:dimensions] = image["imageWidth"] + " x " + image["imageHeight"]
          res[:mime_type] = image["type"]
          res[:file_size] = image["fileSize"].to_i
          res[:size] = (image["fileSize"].to_i / 1024).to_s + " Kb"

          base_id = trim_fedora_uri_to_pid(image["member"])
          base_filename = base_id.gsub(/\:/,"")
          img_filename = base_filename + "." + image["type"].gsub(/^[^\/]+\//,"")
          dc_filename = base_filename + "_dc.xml"

          res[:show_path] = fedora_content_path("show", base_id, "CONTENT", img_filename)
          res[:download_path] = fedora_content_path("download", base_id, "CONTENT", img_filename)
          res[:dc_path] = fedora_content_path('show_pretty', base_id, "DC", dc_filename)
          results << res
        end
      end 
    end
    return results
  end

  def base_id_for(doc)
    doc["id"].gsub(/(\#.+|\@.+)/, "")
  end

  def doc_object_method(doc, method)
    doc["object_display"].first + method.to_s
  end

  def doc_json_method(doc, method)
    hc = HTTPClient.new
    res = JSON.parse(hc.get_content(doc_object_method(doc,method)))

  end

  def get_metadata_list(doc)

    json = doc_json_method(doc, "/ldpd:sdef.Core/describedBy?format=json")["results"]
    json << {"DC" => base_id_for(doc)}
    hc = HTTPClient.new()
    hc.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE

    results = []
    json.each do  |meta_hash|
      meta_hash.each do |desc, uri|
        res = {}
        res[:title] = desc
        res[:id] = trim_fedora_uri_to_pid(uri) 
        block = desc == "DC" ? "DC" : "CONTENT"
        filename = res[:id].gsub(/\:/,"")
        filename += "_" + res[:title].downcase
        filename += ".xml"
        res[:show_url] = fedora_content_path(:show_pretty, res[:id], block, filename)
        res[:download_url] = fedora_content_path(:download, res[:id], block, filename)
        res[:direct_link] = FEDORA_CONFIG[:riurl] + "/get/" + res[:id] + "/" + block
        res[:type] = block == "DC"  ? "DublinCore" : "unknown"
        begin
          res[:xml] = Nokogiri::XML(hc.get_content(res[:direct_link]))
          root = res[:xml].root
          res[:type] = "MODS" if root.name == "mods" && root.attributes["schemaLocation"].value.include?("/mods/")
          extract_mods_details(res)
        rescue
        end

        results << res
      end
    end
    return results
  end

  def extract_mods_details(metadata)
    details = [] 
    xml = metadata[:xml].at_css("mods")

    details << ["Identifier:", xml.at_css("identifier").content]
    xml.css("name").each do |name_node|
      name = ""
      name_node.css("namePart").each  do |np|
        name  += ", " if np.attributes["type"] && np.attributes["type"].value == "date"
        name += np.content
      end

      name_node.css("description").each do |desc|
        name += ", " + desc.content
      end

      details << ["Name:", name] unless name == ""
    end
    metadata[:details] = details
    
    return metadata

  end

  def trim_fedora_uri_to_pid(uri)
    uri.gsub(/info\:fedora\//,"")
  end

  def resolve_fedora_uri(uri)
    FEDORA_CONFIG[:riurl] + "/get" + uri.gsub(/info\:fedora/,"")
  end
end
