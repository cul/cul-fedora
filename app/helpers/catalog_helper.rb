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
        rescue
        end

        extract_mods_details(res)
        results << res
      end
    end
    return results
  end

  def extract_mods_details(metadata)
    details = [] 
    metadata[:details] = []
    xml = metadata[:xml].at_css("mods")

    return metadata unless xml
    
    details += add_mods_details("Identifier:" ,xml.at_css("identifier"))
    xml.css("name").each do |name_node|
      name = parse_mods_name(name_node)
      details << ["Name:", name] unless name == ""


    end

    xml.css("titleInfo").each do |node|
      key = case node.attributes["type"]
      when "translated"
        "Title, translated:"
      when nil
        "Title:"
      else
        "Title, other:"
      end
            
      details << [key, parse_mods_title(node)]
    end



    xml.css("originInfo").each do |origin_node|
      
      details += add_mods_details("Place:", origin_node.css('place>placeTerm[type^="text"]'))
    
      details += add_mods_details("Publisher:", origin_node.css("publisher"))
     
      details += add_mods_date_details("Date Created:", origin_node.css("dateCreated"))
            
      details += add_mods_date_details("Date Issued:", origin_node.css("dateIssued"))
            
      details += add_mods_date_details("Copyright Date:", origin_node.css("copyrightDate"))
     
      details += add_mods_details("Edition:", origin_node.css("edition"))
    end

    details += add_mods_details("Resource type:", xml.css("typeOfResource"))
    details += add_mods_details("Phys. Desc:", xml.css("physicalDescription>extent"))
    details += add_mods_details("Abstract:", xml.at_css("abstract"))

    notes = []
    xml.css("note").each do |note_node|
      if note_node.attributes["displayLabel"] == "Provenance"
        details << ["Provenance:", note_node.content] 
      else
        notes << note_node.content
      end
    end

    details << ["Note:", notes.join(" -- ")] unless notes.empty?



    subjects = []

    xml.css("subject>name,topic,geographic,temporal,titleInfo,name,genre,hierarchicalGeographic,cartographic,geographicCode,occupation"). each do |subject_node|
      if subject_node.name == "name"
        subjects << parse_mods_name(subject_node)
      else
        subjects << subject_node.content
      end
    end

    details << ["Subject(s):", subjects.join(" -- ")]

    details += add_mods_details("Access condition:", xml.css("accessCondition"))

    details += add_mods_details("Location:", xml.css("location>physicalLocation") - xml.css("location>physicalLocation[authority]"))

    xml.css("location>url").each do |url_node|
      details << ["URL:", link_to(url_node.content.to_s.abbreviate(50), url_node.content, :target => "blank")]
    end

    xml.css("relatedItem").each do |related_node|
      title = if related_node.attributes["displayLabel"] == "Collection"
        "Collection"
      elsif related_node.attributes["displayLabel"] == "Project"
        "Project"
      else
        "Related Item"
      end

      related_node.css("titleInfo").each do |title_node|
        details << [title + ":", parse_mods_title(title_node)]
      end

      related_node.css("location>url").each do |url_node|
        details << [title + " URL:", link_to(url_node.content.to_s.abbreviate(50), url_node.content, :target => "blank")]
      end
    end

   
    details += add_mods_details("Record created:", xml.css("recordCreationDate"))
    details += add_mods_details("Record changed:", xml.css("recordChangeDate"))

    
    metadata[:details] = details
    
    return metadata

  end


  def parse_mods_title(node)
  
    value = ""
    
    value += node.at_css("nonSort").content + " " if node.at_css("nonSort")
    value += node.at_css("title").content if node.at_css("title")
    value += " : " + node.at_css("subtitle").content if node.at_css("subtitle")
    value += "  " + node.at_css("partNumber").content if node.at_css("partNumber")
    value += "  " + node.at_css("partName").content if node.at_css("partName")
  
    return value.strip
  end

  def parse_mods_name(name_node)
    name = ""
    name_node.css("namePart").each  do |np|
      name  += ", " if np.attributes["type"] && np.attributes["type"].value == "date"
      name += np.content
    end

    name_node.css("description").each do |desc|
      name += ", " + desc.content
    end

    return name
  end

  def add_mods_details(title, nodes)
    nodes = nodes.listify unless nodes.kind_of?(Nokogiri::XML::NodeSet) 

    nodes.collect { |node| [title, node.content] }
  end


  def add_mods_date_details(title, nodes)
    before_date = nil
    end_date = nil

    nodes.each do |date_node|
      date_value = format_date_if_possible(date_node.content)
      date_value += " (inferred)" if date_node.attributes["qualifier"] == "inferred"

      
      if date_node.attributes.has_key?("point") && date_node.attributes["point"] == "end"
        end_date = " to " + date_value
      else
        before_date = date_value
      end

    end

    if before_date || end_date
      [[title, (before_date.to_s + end_date.to_s).strip]]
    else
      []
    end
  end

  def format_date_if_possible(date, format = :long)
    begin
      Date.parse(date).to_formatted_s(format)
    rescue
      date.to_s
    end
  end


  def trim_fedora_uri_to_pid(uri)
    uri.gsub(/info\:fedora\//,"")
  end

  def resolve_fedora_uri(uri)
    FEDORA_CONFIG[:riurl] + "/get" + uri.gsub(/info\:fedora/,"")
  end
end
