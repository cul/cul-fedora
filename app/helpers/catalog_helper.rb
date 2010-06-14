module CatalogHelper
  def doc_object_method(doc, method)
    doc["object_display"].first + method.to_s
  end

  def doc_json_method(doc, method)
    hc = HTTPClient.new
    res = JSON.parse(hc.get_content(doc_object_method(doc,method)))

  end

  def get_metadata_list(doc)
    
    json = doc_json_method(doc, "/ldpd:sdef.Core/describedBy?format=json")
    json["results"].collect do |meta_hash|
     meta_hash.inject({}) { |h, (k,v)| h[k] = trim_fedora_uri_to_pid(v) ; h }
    end
    
  end

  def trim_fedora_uri_to_pid(uri)
    uri.gsub(/info\:fedora\//,"")
  end

  def resolve_fedora_uri(uri)
    FEDORA_CONFIG[:riurl] + "/get" + uri.gsub(/info\:fedora/,"")
  end
end
