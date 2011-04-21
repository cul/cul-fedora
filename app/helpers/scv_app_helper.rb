module ScvAppHelper
  include ApplicationHelper
  def application_name
    "Columbia University Libraries Staff Collection Viewer Prototype"
  end
  # RSolr presumes one suggested word, this is a temporary fix
  def get_suggestions(spellcheck)
    words = []
    return words if spellcheck.nil?
    suggestions = spellcheck[:suggestions]
    i_stop = suggestions.index("correctlySpelled")
    0.step(i_stop - 1, 2).each do |i|
      term = suggestions[i]
      term_info = suggestions[i+1]
      origFreq = term_info['origFreq']
  # termInfo['suggestion'] is an array of hashes with 'word' and 'freq' keys
      term_info['suggestion'].each do |suggestion|
        if suggestion['freq'] > origFreq
          words << suggestion['word']
        end
      end
    end
    words
  end
  #
  # facet param helpers ->
  #

  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  # first arg item is a facet value item from rsolr-ext.
  # options consist of:
  # :suppress_link => true # do not make it a link, used for an already selected value for instance
  def render_facet_value(facet_solr_field, item, options ={})
    link_to_unless(options[:suppress_link], item.label, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" + render_subfacets(facet_solr_field, item, options)
  end

  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value(facet_solr_field, item)
    '<span class="selected">' +
    link_to_unless(true, item.label, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select") + " (" + format_num(item.hits) + ")" +
    '</span>' +
    ' [' + link_to("remove", remove_facet_params(facet_solr_field, item.value, params), :class=>"remove") + ']' +
    render_subfacets(facet_solr_field, item)
  end
  def render_subfacets(facet_solr_field, item, options ={})
    render = ''
    if (item.instance_variables.include? "@subfacets")
      render = '<span class="toggle">[+/-]</span><ul>'
      item.subfacets.each do |subfacet|
        if facet_in_params?(facet_solr_field, subfacet.value)
          render += '<li>' + render_selected_facet_value(facet_solr_field, subfacet) + '</li>'
        else
          render += '<li>' + render_facet_value(facet_solr_field, subfacet,options) + '</li>'
        end
      end
      render += '</ul>'
    end
    render
  end
  def render_document_partial_with_locals(doc, action_name, locals={})
    format = document_partial_name(doc)
    locals = locals.merge({:document=>doc})
    begin
      render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>locals
    rescue ActionView::MissingTemplate
      render :partial=>"catalog/_#{action_name}_partials/default", :locals=>locals
    end
  end

  def url_to_document(doc)
    catalog_path(doc[:id])
  end
  def onclick_to_document(document, formdata = {})
    data = {:counter => nil, :results_view => true}.merge(formdata)
    _opts = {:method=>:put,:data=>data,:class=>nil}
    _opts = _opts.stringify_keys
    convert_options_to_javascript_with_data!(_opts,url_to_document(document))
    _opts["onclick"]
  end
  # url_back_to_catalog(:label=>'Back to Search')
  # Create a url pointing back to the index screen, keeping the user's facet, query and paging choices intact by using session.
  def url_back_to_catalog(opts={:label=>'Back to Search'})
    query_params = session[:search] ? session[:search].dup : {}
    query_params.delete :counter
    query_params.delete :total
    return catalog_index_path(query_params)
  end
def link_to_previous_document(doc)
    return if doc == nil
    label="\xe3\x80\x8a Previous"
    link_to_with_data label, catalog_path(doc[:id]), {:method=>:put, :class=>"previous", :data=>{:label=>label, :counter => session[:search][:counter].to_i - 1, :display_members =>session[:search][:display_members]}}
  end

  def link_to_next_document(doc)
    return if doc == nil
    label="Next \xe3\x80\x8b"
    link_to_with_data label, catalog_path(doc[:id]), {:method=>:put, :class=>"next", :data=>{:label=>label, :counter => session[:search][:counter].to_i + 1, :display_members =>session[:search][:display_members]}}
  end
end
