module Cul
  module Fedora
    class Solr
      attr_reader :url
      def initialize(config = {})
        @url = config[:url] || raise(ArgumentError, "must provide url")

      end

      def rsolr
        @rsolr ||= RSolr.connect(:url => @url)
      end

      def ingest(options = {})
        format = options.delete(:format) || raise(ArgumentError, "needs format")
        items = options.delete(:items) || []
        items = [items] unless items.kind_of?(Array)
        
        collections = options.delete(:collections) || []
        collections = [collections] unless collections.kind_of?(Array)
        collections.each do |collection|
          items |= collection.listMembers
        end



        rsolr.add(items.collect { |i| i.send("index_for_#{format}")}.reject { |doc| doc == {}})
       
        rsolr.commit
      end

    end
    

  end
end
