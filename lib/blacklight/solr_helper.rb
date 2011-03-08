# SolrHelper is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
# class CatalogController < ActionController::Base
#   
#   include Blacklight::SolrHelper
#   
#   def solr_search_params
#     super.merge :per_page=>10
#   end
#   
# end
#
require_dependency('vendor/plugins/blacklight/lib/blacklight/solr_helper.rb')
module Blacklight::SolrHelper
  
  def self.included(mod)
    if mod.respond_to?(:helper_method)
      mod.helper_method(:facet_limit_hash)
      mod.helper_method(:facet_limit_for)
      mod.helper_method(:facet_sort_hash)
      mod.helper_method(:facet_sort_for)
    end
  end

  # a solr query method
  # used to paginate through a single facet field's values
  # /catalog/facet/language_facet
  def get_facet_pagination(facet_field, extra_controller_params={})
    extra_controller_params = {Blacklight::Solr::FacetPaginator.request_keys[:sort] => facet_sort_for(facet_field)}.merge(extra_controller_params)
    #puts "get_facet_pagination: getting facets for #{facet_field} sorted by " + extra_controller_params[Blacklight::Solr::FacetPaginator.request_keys[:sort]]
    solr_params = solr_facet_params(facet_field, extra_controller_params)
    #puts "get_facet_pagination: solr_facet_params: " + solr_params
    
    # Make the solr call
    response = Blacklight.solr.find(solr_params)

    limit =       
      if respond_to?(:facet_list_limit)
        facet_list_limit.to_s.to_i
      elsif solr_params[:"f.#{facet_field}.facet.limit"]
        solr_params[:"f.#{facet_field}.facet.limit"] - 1
      else
        nil
      end

    
    # Actually create the paginator!
    # NOTE: The sniffing of the proper sort from the solr response is not
    # currently tested for, tricky to figure out how to test, since the
    # default setup we test against doesn't use this feature. 
    return Blacklight::Solr::FacetPaginator.new(response.facets.first.items, 
      :offset => solr_params['facet.offset'], 
      :limit => limit,
      :sort => solr_params['facet.sort']
    )
  end
  
  # a solr query method
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  def get_single_doc_via_search(extra_controller_params={})
    solr_params = solr_search_params(extra_controller_params)
    solr_params[:per_page] = 1
    solr_params[:rows] = 1
    solr_params[:fl] = '*'
    Blacklight.solr.find(solr_params).docs.first
  end
    
  # Look up facet limit for given facet_field. Will look at config, and
  # if config is 'true' will look up from Solr @response if available. If
  # no limit is avaialble, returns nil. Used from #solr_search_params
  # to supply f.fieldname.facet.limit values in solr request (no @response
  # available), and used in display (with @response available) to create
  # a facet paginator with the right limit. 
  def facet_sort_for(facet_field)
    sorts_hash = facet_sort_hash
    puts sorts_hash.to_s
    return "count" unless sorts_hash
     
    sort = sorts_hash[facet_field]
    puts "Found sort \"#{sort}\" for field \"#{facet_field}\" in hash"
    if ( sort == true && @response && 
         @response["responseHeader"] && 
         @response["responseHeader"]["params"])
      _sort =
       @response["responseHeader"]["params"]["f.#{facet_field}.facet.sort"] || 
       @response["responseHeader"]["params"]["facet.sort"]
      puts "Found sort #{_sort} for field #{facet_field} in response"
      sort = _sort if _sort
    elsif sort == true # but was disregarded by solr
      puts "Found ignored sort #{sort} for field #{facet_field} in hash"
      sort = "count"
    elsif not sort
      sort = "count"
    end
    puts "Returning sort #{sort} for field #{facet_field}"

    return sort
  end

  # Returns complete hash of key=facet_field, value=sort.
  # Used by SolrHelper#solr_search_params to choose default sort for solr
  # request for all configured facet limits.
  def facet_sort_hash
    Blacklight.config[:facet][:sorts]           
  end
  
end
