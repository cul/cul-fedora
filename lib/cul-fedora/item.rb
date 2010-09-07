module Cul
  module Fedora
    class Item
      attr_reader :server, :pid

      URI_TO_PID = 'info:fedora/'
     
      

      def initialize(server, uri)
        @server = server
        @pid = uri.sub(URI_TO_PID, "")
      end

      def ==(other)
        self.server == other.server
        self.pid == other.pid
      end

    end
  end
end
