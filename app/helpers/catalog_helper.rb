module CatalogHelper
  def doc_object_method(doc, method)
    doc["object_display"].first + method.to_s
  end

end
