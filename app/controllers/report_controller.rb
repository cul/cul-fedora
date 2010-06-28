class ReportController < ApplicationController
  def by_collection
    @results = {}
    page = 0
    per_page = 100
    query_params = {:q => "", :fl => "object_display,id,collection_h", :per_page => per_page, :facets => {:fields => ['collection_h']}}

    while
      page_results = Blacklight.solr.find(query_params.merge(:page => page))
      
      page_results["response"]["docs"].each do |r|
        collections = []
        
        if (collection_h = r["collection_h"])
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
        
        collections.each do |coll|
          @results[coll] = {:count => 0} unless @results[coll]
          @results[coll][:count] += 1
        end

      end
      
      break if page_results["response"]["start"] + per_page >  page_results["response"]["numFound"]
      
      page += 1

    end

  end
end
