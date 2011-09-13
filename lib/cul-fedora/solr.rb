module Cul
  module Fedora
    class Solr
      
      attr_reader :url
      
      def initialize(config = {})
        @url = config[:url] || raise(ArgumentError, "must provide url")
        @logger = config[:logger]
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
          results = rsolr.select({:q => "", :fl => "id", :start => start, :rows => rows})
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
        process = options.delete(:process) || nil
        skip = options.delete(:skip) || nil

        processed_successfully = 0
        
        logger.info "Preparing the items for indexing..."
        collections.each do |collection|
          items |= collection.listMembers
        end

        items.sort!

        to_add = []
        results = Hash.new { |h,k| h[k] = [] }
        errors = {}
      
        item_pids = []
        items.each do |item|
          item_pids << item.pid
        end
        if delete == true
          delete_removed(fedora_server, item_pids)
        end
      
        logger.info "Preparing to index " + items.length.to_s + " items..."
      
        items.each do |i|
          
          if(ignore.index(i.pid).nil? == false)
            logger.info "Ignoring " + i.pid + "..."
            next
          end
          
          if process && skip && skip > 0
            skip -= 1
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

          results[result_hash[:status]]  << i.pid

          case result_hash[:status]
          when :success
            to_add << result_hash[:results]
            processed_successfully += 1
          when :error
            errors[i.pid] = result_hash[:error_message]
          end

          if process
            process -= 1
            break if process <= 0
          end

          if to_add.length >= 500
            logger.info "Adding batch to commit queue..."
            rsolr.add(to_add)
            to_add.clear
          end

        end
        
        if to_add.length > 0
          logger.info "Adding batch to commit queue..."
          rsolr.add(to_add)
          to_add.clear
        end
        
        logger.info "Committing changes to Solr..."
        rsolr.commit

        return {:results => results, :errors => errors, :processed_successfully => processed_successfully}

      end

    end
  end
end
