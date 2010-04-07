module Blacklight::Solr::Hfacets
  
  # shortcut method for setting up a Paginator instance
  def self.paginate(params)
    params['facet.limit'] ||= 6
    raise '[:facet][:fields] is required' if ! params[:facets] or ! params[:facets][:fields]
    raise "['facet.offset'] is required" unless params['facet.offset']
    params[:rows] = 0
    response = Blacklight.solr.find(params)
    Paginator.new(response.facets.first.items, params['facet.offset'], params['facet.limit'])
  end

  class Subfacet
    attr_accessor :value, :hits, :label
    def subfacets
      @subfacets
    end
    def subfacets=(value)
      @subfacets = value
    end
    def initialize(*value)
      @value = value[0]
    end
  end
  
  #
  # Pagination for facet values -- works by setting the limit to (max + 1)
  # If limit is 6, then the resulting facet value items.size==5
  # This is a workaround for the fact that Solr itself can't compute
  # the total values for a given facet field,
  # so we cannot know how many "pages" there are.
  #
  class Paginator
    
    attr_reader :total, :items, :previous_offset, :next_offset

    def initialize(top_level_values, offset, limit)
      offset = offset.to_s.to_i
      limit = limit.to_s.to_i
      total = top_level_values.size
      @items = subfacets(top_level_values).slice(0, limit-1)
      @has_next = total == limit
      @has_previous = offset > 0
      @next_offset = offset + (limit-1)
      @previous_offset = offset - (limit-1)
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
    items = Array.new()
    if (! subfacet_values )
      return items
    end
    items.push(Subfacet.new())
    (0...subfacet_values.size).step(2) do |i|
       name = subfacet_values[i]
       value = subfacet_values[i+1]
       if (name =~ /^path\-.*/) :
         items.last.value = value
       elsif (name.eql? 'sub_facets') :
         items.last.subfacets = Blacklight::Solr::Hfacets.subfacets(value)
       else
         if (items.last.label) :
           items.push(Subfacet.new())
         end
         items.last.label = name
         items.last.hits = value.to_i
       end
    end
    return items
  end
end
