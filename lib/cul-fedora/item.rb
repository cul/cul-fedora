module Cul
  module Fedora
    class Item
      attr_reader :server, :pid

      URI_TO_PID = 'info:fedora/'
     
      

      def initialize(*args)
        options = args.extract_options!
        @server = options[:server] || Server.new(options[:server_config])
        @pid = options[:pid] || options[:uri] || raise(ArgumentError, "requires uri or pid")
        @pid = @pid.to_s.sub(URI_TO_PID, "")
      end

      def ==(other)
        self.server == other.server
        self.pid == other.pid
      end

    end
  end
end
