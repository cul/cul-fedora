module Blacklight::Solr::Hfacets
  
  # shortcut method for setting up a Paginator instance
  def self.paginate(params)
    params['facet.limit'] ||= 6
    raise '[:facet][:fields] is required' if ! params[:facets] or ! params[:facets][:fields]
    raise "['facet.offset'] is required" unless params['facet.offset']
    params[:rows] = 0
    response = Blacklight.solr.find(params)
    FacetPaginator.new(response.facets.first.items, {:offset => params['facet.offset'], :limit => params['facet.limit']})
  end

  class SubfacetItem < RSolr::Ext::Response::Facets::FacetItem
    attr_accessor :subfacets, :label
  end
  
  class FacetPaginator < Blacklight::Solr::FacetPaginator
    
    attr_reader :total, :items, :previous_offset, :next_offset, :limit, :sort

    def initialize(values, arguments)
      @offset = arguments[:offset].to_s.to_i
      @limit = arguments[:limit].to_s.to_i
      @sort = arguments[:sort].to_s.to_i
      total = values.size
      if (@limit)
        @items = values.slice(0, @limit)
        @has_next = total > @limit
        @has_previous = @offset > 0
      else
        @items = values
        @has_next = false
        @has_previous = false
      end
    end

    def has_next?
      @has_next
    end

    def has_previous?
      @has_previous
    end
    
  end

  def self.subfacets(subfacet_values)
    # a hfacet item has a label, a count, and a value. It may have subfacets.
    # parsing is hinky because of the flat list of returned values
    warn "called Hfacets.subfacets"
    items = Array.new()
    if (! subfacet_values )
      p "nil/false for subfacet_values"
      return items
    end
    template = {:v=>nil, :h=>nil, :l=>nil, :s=>nil}
    i = 0
    #(0...subfacet_values.size).step(2) do |i|
    while i < subfacet_values.size
       name = subfacet_values[i]
       value = subfacet_values[i+1]
       p name.to_s + " : " + value.to_s
       if (name =~ /^path\-.*/) :
         template[:v] = value
       elsif (name.eql? 'sub_facets') :
         template[:s] = Blacklight::Solr::Hfacets.subfacets(value)
       else
         if (!template[:l].nil?) :
           items.push(SubfacetItem.new(template[:v],template[:h]))
           items.last.subfacets= (template[:s].nil?)?[]:template[:s]
           items.last.label= template[:l]
           template = {:v=>nil, :h=>nil, :l=>nil, :s=>nil}
         end
         template[:l] = name
         template[:h] = value.to_i
       end
    i += 4
    end
    items.push(SubfacetItem.new(template[:v],template[:h]))
    items.last.subfacets= (template[:s].nil?)?[]:template[:s]
    items.last.label= template[:l]
    return items
  end
end
