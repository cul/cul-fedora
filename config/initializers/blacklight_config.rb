# You can configure Blacklight from here. 
#   
#   Blacklight.configure(:environment) do |config| end
#   
# :shared (or leave it blank) is used by all environments. 
# You can override a shared key by using that key in a particular
# environment's configuration.
# 
# If you have no configuration beyond :shared for an environment, you
# do not need to call configure() for that envirnoment.
# 
# For specific environments:
# 
#   Blacklight.configure(:test) {}
#   Blacklight.configure(:development) {}
#   Blacklight.configure(:production) {}
# 

Blacklight.configure(:shared) do |config|

  # Set up and register the default SolrDocument Marc extension
  SolrDocument.extension_parameters[:marc_source_field] = :marc_display
  SolrDocument.extension_parameters[:marc_format_type] = :marc21
  SolrDocument.use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end

  
  # default params for the SolrDocument.search method
  SolrDocument.default_params[:search] = {
    :qt=>:search,
    :per_page => 10,
    :facets => {:fields=>
      ["format",
        "language_facet",
        "lc_1letter_facet",
        "lc_alpha_facet",
        "lc_b4cutter_facet",
        "language_facet",
        "pub_date",
        "subject_era_facet",
        "subject_geo_facet",
        "subject_topic_facet",
        "lib_repo_facet",
        "lib_date_facet",
        "lib_name_facet",
        "lib_format_facet",
        "lib_project_facet",
        "lib_collection_facet",
        "subject_topic_facet"]
    }  
  }
  
  # default params for the SolrDocument.find_by_id method
  SolrDocument.default_params[:find_by_id] = {:qt => :document}
  
  
  ##############################
  
  
  config[:default_qt] = "search"
  

  # solr field values given special treatment in the show (single result) view
  config[:show] = {
    :html_title => "title_display",
    :heading => "title_display",
    :display_type => "format"
  }

  # solr fld values given special treatment in the index (search results) view
  config[:index] = {
    :show_link => "title_display",
    :num_per_page => 10,
    :record_display_type => "format"
  }

  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display
  # TODO: Reorganize facet data structures supplied in config to make simpler
  # for human reading/writing, kind of like search_fields. Eg,
  # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
  config[:facet] = {
    :field_names => [
      "lib_project_facet",
      "lib_name_facet",
      "lib_date_facet",
      "lib_format_facet",
      "lib_collection_facet",
      "lib_repo_facet",
      "format_h",
      "collection_h",
      "date_created_h",
      "pub_date",
      "subject_topic_facet",
      "language_facet",
      "descriptor",
      "lc_1letter_facet",
      "subject_geo_facet",
      "subject_era_facet"
    ],
    :labels => {
      "lib_project_facet"              => "Project",
      "lib_name_facet"            => "Names",
      "lib_date_facet"            => "Date",
      "lib_format_facet"              => "Format",
      "lib_collection_facet"              => "Collection",
      "lib_repo_facet"            => "Repository",
      "format_h"              => "Routed as",
      "collection_h"              => "In Hierarchy",
      "date_created_h"              => "Date (Experimental)",
      "subject_topic_facet" => "Topic",
      "descriptor"          => "Metadata Type",
      "language_facet"      => "Language",
      "lc_1letter_facet"    => "Call Number",
      "subject_era_facet"   => "Era",
      "subject_geo_facet"   => "Region"
    },
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # If left unset, then all facet values returned by solr will be displayed.
    # nil key can be used for a default limit applying to all facets otherwise
    # unspecified. 
    # limit value is the actual number of items you want _displayed_,
    # #solr_search_params will do the "add one" itself, if neccesary.
    :limits => {
      nil => 10,
      "subject_facet" => 20
    },
    :hierarchy => {
      "format_h" => true,
      "date_created_h" => true,
      "collection_h" => true
    }
  }

  # solr fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display 
  config[:index_fields] = {
    :field_names => [
      "title_display",
      "title_vern_display",
      "author_display",
      "author_vern_display",
      "lib_format_display",
      "format",
      "lib_collection_display",
      "lib_repo_display",
      "language_facet",
      "published_display",
      "object_display",
      "lc_callnum_display"
    ],
    :labels => {
      "title_display"           => "Title:",
      "title_vern_display"      => "Title:",
      "author_display"          => "Author:",
      "author_vern_display"     => "Author:",
      "lib_format_display"                  => "Format:",
      "format"                  => "Routing:",
      "lib_collection_display"  => "Collection:",
      "lib_repo_display"  => "Repository:",
      "language_facet"          => "Language:",
      "published_display"       => "Published:",
      "object_display"          => "In Fedora:",
      "lc_callnum_display"      => "Call number:"
    }
  }

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display 
  config[:show_fields] = {
    :field_names => [
      "title_display",
      "title_vern_display",
      "subtitle_display",
      "subtitle_vern_display",
      "author_display",
      "author_vern_display",
      "lib_format_display",
      "format",
      "lib_collection_display",
      "lib_repo_display",
      "url_fulltext_display",
      "url_suppl_display",
      "material_type_display",
      "language_facet",
      "published_display",
      "published_vern_display",
      "lc_callnum_display",
      "object_display",
      "isbn_t"
    ],
    :labels => {
      "title_display"           => "Title:",
      "title_vern_display"      => "Title:",
      "subtitle_display"        => "Subtitle:",
      "subtitle_vern_display"   => "Subtitle:",
      "author_display"          => "Author:",
      "author_vern_display"     => "Author:",
      "lib_format_display"                  => "Format:",
      "format"                  => "Routing:",
      "lib_collection_display"  => "Collection:",
      "lib_repo_display"  => "Repository:",
      "url_fulltext_display"    => "URL:",
      "url_suppl_display"       => "More Information:",
      "material_type_display"   => "Physical description:",
      "language_facet"          => "Language:",
      "published_display"       => "Published:",
      "published_vern_display"  => "Published:",
      "lc_callnum_display"      => "Call number:",
      "object_display"          => "In Fedora:",
      "isbn_t"                  => "ISBN:"
    }
  }


  # "fielded" search configuration. Used by pulldown among other places.
  # For supported keys in hash, see rdoc for Blacklight::SearchFields
  config[:search_fields] ||= []
  config[:search_fields] << {:display_label => 'All Fields', :qt => 'search'}
  config[:search_fields] << {:display_label => 'Title', :qt => 'title_search'}
  config[:search_fields] << {:display_label =>'Author', :qt => 'author_search'}
  config[:search_fields] << {:display_label => 'Subject', :qt=> 'subject_search'}
  
  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  # label is key, solr field is value
  config[:sort_fields] ||= []
  config[:sort_fields] << ['relevance', 'score desc, date_created_dt desc, title_sort asc']
  config[:sort_fields] << ['year', 'date_created_dt desc, title_sort asc']
  config[:sort_fields] << ['name', 'name_facet asc, title_t asc']
  config[:sort_fields] << ['title', 'title_sort asc, date_created_dt desc']
  
  # If there are more than this many search results, no spelling ("did you 
  # mean") suggestion is offered.
  config[:spell_max] = 5
end

