module Cul
  module Fedora
    class Server
      attr_reader :riurl, :riquery

      def initialize(*args)
        options = args.extract_options!
        @riurl = options[:riurl] || raise(ArgumentError, "Must provide riurl argument")
        @riquery = options[:riquery] || raise(ArgumentError, "Must provide riquery argument")
        @hc = options[:http_client] 
      end

      def item(uri)
        Item.new(:server => self, :uri => uri)
      end



      def request(options= {})
        http_client.get_content(*request_path(options))
      end

      def request_path(options = {})
        sdef = options.delete(:sdef).to_s
        pid = options.delete(:pid).to_s
        request = options.delete(:request).to_s
        method = (options.delete(:method) || "/get").to_s
        raise(ArgumentError, "request necessary") if request.empty?

        sdef = "/" + sdef unless sdef.empty?
        pid = "/" + pid unless pid.empty?
        request = "/" + request.to_s


        uri = @riurl + method + pid + sdef + request
        query = options
        
        return [uri, query]
      end

      def inspect
        '#<Cul::Fedora::Server:' + self.object_id.to_s + ' @riurl="' + @riurl + '">'  
      end

      private

      def http_client
        @hc ||= HTTPClient.new()
        @hc
      end
    end
  end
end

