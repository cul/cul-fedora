module Cul
  module Fedora
    class Solr
      attr_reader :url
      def initialize(config = {})
        @url = config["url"] || raise(ArgumentError, "must provide url")

      end
    end
  end
end
