module RSolr::Ext::Response::Facets
 class SubfacetItem < FacetItem
   attr_accessor :subfacets, :label
 end

 module LabelledFacet
  def label=(arg)
    @label=arg
  end
  def label
    @label
  end
 end

 def facets
   @facets ||= (
    facet_fields.map do |(facet_field_name, values)|
      items = subfacets(facet_field_name, values)
      FacetField.new(facet_field_name, items)
    end
   )
 end
 def subfacets(name, subfacet_values)
    # a hfacet item has a label, a count, and a value. It may have subfacets.
    # parsing is hinky because of the flat list of returned values
    items = []
    if (! subfacet_values )
      return items
    end
    i = 0
    while i < subfacet_values.size
      _label = subfacet_values[i]
      _value = subfacet_values[i]
      _hits = subfacet_values[i+1]
      _subfacets = nil
      if (_label.eql? 'sub_facets'):
        items = subfacets(name, _hits)
        break
      end
      if (i+2 < subfacet_values.size and subfacet_values[i+2]  =~ /^path\-.*/):
        _value = subfacet_values[i+3]
        i += 2
        if (i+2 < subfacet_values.size and subfacet_values[i+2].eql? 'sub_facets') :
          _subfacets = subfacets(name, subfacet_values[i+3])
          i += 2
        end
      end
      if (_subfacets.nil?):
        items.push(FacetItem.new(_value,_hits))
        items.last.extend(LabelledFacet)
      else
        items.push(SubfacetItem.new(_value,_hits))
        items.last.subfacets= _subfacets
      end
      items.last.label = _label
      i += 2
    end
    return items
 end
end
