begin
  require "active_support/core_ext/array/extract_options"
rescue
  require "activesupport"
end

module Cul
  module Fedora
    class Solr
      
      attr_reader :url
      
      def initialize(options = {})
        @url = options[:url] || options["url"] || raise(ArgumentError, "must provide url")
        @logger = options[:logger] || options["logger"]
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def item_exists?(item)
        !rsolr.find(:filters => {:id => item.pid_escaped})["response"]["docs"].empty?
      end

      def rsolr
        @rsolr ||= RSolr.connect(:url => @url)
      end

      def delete_index
        logger.info "Deleting Solr index..."
        rsolr.delete_by_query("*:*")
        rsolr.commit
      end
      
      def delete_removed(fedora_server, fedora_item_pids = nil)
        
        removed = identify_removed(fedora_server)
        logger.info "Deleting items removed from Fedora..."
        removed.each do |id|
          logger.info "Deleting " + id + "..."
          rsolr.delete_by_query("id:" + id.to_s.gsub(/:/,'\\:'))
        end
        
        rsolr.commit
        
      end
      
      def identify_removed(fedora_server, fedora_item_pids = nil)
        start = 0
        rows = 500
        removed = []
        results = rsolr.select({:q => "", :fl => "id", :start => start, :rows => rows})
        logger.info "Identifying items removed from Fedora..."
        while(!results["response"]["docs"].empty?)
          
          logger.info("Checking Solr index from " + start.to_s + " to " + (start + rows).to_s + "...")
          results["response"]["docs"].each do |doc|
            
            if(fedora_item_pids.nil?)
              if(!fedora_server.item(doc["id"]).exists?)
                logger.info "Noting removed item " + doc["id"] + "..."
                removed << doc["id"].to_s
              end
            else
              if(!fedora_item_pids.include?(doc["id"].to_s))
                logger.info "Noting removed item " + doc["id"] + "..."
                removed << doc["id"].to_s
              end
            end
            
          end
          
          start = start + rows
          results = rsolr.get 'select', :params => {:q => "", :fl => "id", :start => start, :rows => rows}
        end
        return removed
      end
      
      def ingest(options = {})
        
        format = options.delete(:format) || raise(ArgumentError, "needs format")
        fedora_server = options.delete(:fedora_server) || raise(ArgumentError, "needs fedora server")

        items = options.delete(:items) || []
        items = [items] unless items.kind_of?(Array)
        collections = options.delete(:collections) || []
        collections = [collections] unless collections.kind_of?(Array)
        ignore = options.delete(:ignore) || []
        ignore = [ignore] unless ignore.kind_of?(Array)

        delete = options.delete(:delete_removed) || false
        overwrite = options.delete(:overwrite) || false
        skip = options.delete(:skip) || []

        indexed_count = 0
        
        logger.info "Preparing the items for indexing..."
        collections.each do |collection|
          items |= collection.listMembers
        end

        items.sort!

        results = Hash.new { |h,k| h[k] = [] }
        errors = []
      
        item_pids = []
        items.each do |item|
          item_pids << item.pid
        end
        if delete == true
          delete_removed(fedora_server, item_pids)
        end
      
        logger.info "Preparing to index " + items.length.to_s + " items..."
      
        items.each do |i|
          
          if(ignore.index(i.pid).nil? == false || skip.index(i.pid).nil? == false)
            logger.info "Ignoring/skipping " + i.pid + "..."
            results[:skipped] << i.pid
            next
          end
           
          if item_exists?(i)
            unless overwrite == true
              results[:skipped] << i.pid
              next
            end
          end    

          logger.info "Indexing " + i.pid + "..."

          result_hash = i.send("index_for_#{format}", options)

          results[result_hash[:status]] << i.pid

          case result_hash[:status]
          when :success
            begin
              rsolr.add(result_hash[:results])
              indexed_count += 1
            rescue Exception => e
              errors << i.pid
              logger.error e.message
            end
          when :error
            errors << i.pid
            logger.error result_hash[:error_message]
          end

        end
        
        logger.info "Committing changes to Solr..."
        rsolr.commit

        return {:results => results, :errors => errors, :indexed_count => indexed_count}

      end

    end
  end
end
