class Report < ActiveRecord::Base
  belongs_to :user
  
  VALID_CATEGORIES = %w{by_collection}
  
  validates_presence_of :name
  validates_inclusion_of :category, :in => VALID_CATEGORIES

  def generate!
    self.generated_on = Time.now
    self.data = Report.generate(category, options_hash).to_json
    return self
  end

  
  

  def data_hash
    begin
      JSON.parse(data.to_s)
    rescue
      {}
    end
  end

  def options_hash
    begin
      JSON.parse(options.to_s)
    rescue
      {}
    end
  end

  def self.generate(category,options = {})
    self.send("generate_#{category.to_s}",options)
  end

  private
  
  def self.generate_by_collection_and_size(options = {})
    self.generate_by_collection(options.merge(:size => true))
  end

  def self.generate_by_collection(options = {})

    collections = {}
    formats = []

    page = 0
    per_page = 100 
    query_params = {:q => "", :fl => "format, object_display,id,collection_h", :per_page => per_page, :facets => {:fields => ['collection_h']}}

    while
      page_results = Blacklight.solr.find(query_params.merge(:page => page))
      
      page_results["response"]["docs"].each do |r|
        collection_list = collection_list_for_doc(r) 
        format = r["format"] || "No format"
        formats << format
        collection_list.each do |coll|
          collections[coll] ||= {:count => 0} 
          collections[coll][:count] += 1

          collections[coll][format] ||= 0
          collections[coll][format] += 1

        end

     
      end
      break if page_results["response"]["start"] + per_page >  page_results["response"]["numFound"]
      
      page += 1

    end

    formats.uniq!.sort!
  
    {"collections" => collections, "formats" => formats}
  end
  
  def self.collection_list_for_doc(doc)
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
