module Cul
  module Fedora
    class Solr
      attr_reader :url
      def initialize(config = {})
        @url = config[:url] || raise(ArgumentError, "must provide url")

      end

      def item_exists?(item)
        !rsolr.find(:filters => {:id => item.pid_escaped})["response"]["docs"].empty?
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

        overwrite = options.delete(:overwrite) || false
        process = options.delete(:process) || nil
        skip = options.delete(:skip) || nil



        collections.each do |collection|
          items |= collection.listMembers
        end

        items.sort!

        to_add = []
        results = Hash.new { |h,k| h[k] = [] }
        errors = {}
      
        items.each do |i|
          if process && skip && skip > 0
            skip -= 1
            next
          end

           
          if item_exists?(i)
            
            unless overwrite
              results[:skipped] << i.pid
              next
            end
          end    
          



          result_hash = i.send("index_for_#{format}", options)

          results[result_hash[:status]]  << i.pid

          case result_hash[:status]
          when :success
            to_add << result_hash[:results]
          when :error
            errors[i.pid] = result_hash[:error_message]
          end

          if process
            process -= 1
            break if process <= 0
          end

        end
          
        rsolr.add(to_add)
        rsolr.commit

        return {:results => results, :errors => errors}

      end

    end


  end
end
