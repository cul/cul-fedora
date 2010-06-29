class ReportController < ApplicationController
  
  def by_collection
    @collections = {}
    @formats = []

    page = 0
    per_page = 100 
    query_params = {:q => "", :fl => "format, object_display,id,collection_h", :per_page => per_page, :facets => {:fields => ['collection_h']}}

    while
      page_results = Blacklight.solr.find(query_params.merge(:page => page))
      
      page_results["response"]["docs"].each do |r|
        collections = collection_list_for_doc(r) 
        format = r["format"] || "No format"
        @formats << format
        collections.each do |coll|
          @collections[coll] ||= {:count => 0} 
          @collections[coll][:count] += 1

          @collections[coll][format] ||= 0
          @collections[coll][format] += 1

        end

        
      end
      break if page_results["response"]["start"] + per_page >  page_results["response"]["numFound"]
      
      page += 1

    end

    @formats.uniq!.sort!

  end

  private

  def collection_list_for_doc(doc)
    collections = []

    if (collection_h = doc["collection_h"])
      collection_h.each do |collection|
        collection_list = collection.split("/")
        collection_list.delete_at(0)
        collection_list.each_index do |i|
          collections << collection_list[0..i].join("/")
        end
      end
    end

    collections << "No Collection" if collections.empty?
    collections << "All"

    return collections
  end
end
