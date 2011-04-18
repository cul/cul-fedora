module Cul
module Fedora
  TRIPLES_QUERY_TEMPLATE = <<-hd.gsub(/\s+/, " ").strip
select $predicate $object from <#ri>
where <info:fedora/$PID> $predicate $object
hd
  class MimeDummy
    attr_reader :mime_type, :models
    def initialize(mime_type, models=[])
      @mime_type=mime_type
      @models=models
    end
  end
  module Aggregator
    DESCRIPTION_QUERY_TEMPLATE = "select $description from <#ri> where $description <http://purl.oclc.org/NET/CUL/metadataFor> <info:fedora/$PID> order by $description".gsub(/\s+/, " ").strip
    module ImageAggregator
      MEMBER_QUERY_TEMPLATE = <<-hd.gsub(/\s+/, " ").strip
select $member $imageWidth $imageHeight $type $fileSize from <#ri> 
where $member <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/$PID> 
and $member <dc:format> $type
and $member <http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth> $imageWidth 
and $member <http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageLength> $imageHeight 
and $member <http://purl.org/dc/terms/extent> $fileSize order by $fileSize
hd
   def gen_member_query(document)
     if @memberquery
       @memberquery
     else
       if document[:pid_s]
         if document[:pid_s].kind_of? String
           @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_s])
         else
           @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_s].first)
         end
       else
         _pid = document[:id]
         _pid = _pid.split('@')[0]
         @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,_pid)
       end
       @memberquery
     end
   end
    end
    module ContentAggregator
      MEMBER_QUERY_TEMPLATE = "select $member $type subquery( select $dctype $title from <#ri> where $member <dc:type> $dctype and $member <dc:title> $title) where $member <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/$PID> and $member <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> $type".gsub(/\s+/, " ").strip
   def gen_member_query(document)
     if @memberquery
       @memberquery
     else
       if document[:pid_s].kind_of? String
         @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_s])
       else
         @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_s].first)
       end
       @memberquery
     end
   end
  end
  end
  module Objects
    class BaseObject
      def initialize(document, client=HTTPClient.new)
        @riurl = FEDORA_CONFIG[:riurl] + '/risearch'
        @http_client = client
        if document[:pid_s].nil?
            _pid = document[:id].split('@')[0]
        else
          _pid = (document[:pid_s].kind_of? String) ? document[:pid_s] : document[:pid_s].first
        end
        @metadataquery = Cul::Fedora::Aggregator::DESCRIPTION_QUERY_TEMPLATE.gsub(/\$PID/,_pid)
        @triplesquery = Cul::Fedora::TRIPLES_QUERY_TEMPLATE.gsub(/\$PID/,_pid)
      end
      def riquery(query)
        query = {:query=>query}
        query[:format] = 'json'
        query[:type] = 'tuples'
        query[:lang] = 'itql'
        query[:limit] = ''
        res = @http_client.get_content(@riurl,query)
        JSON.parse(res)["results"]
      end
      def metadata_list
        @metadatas = riquery(@metadataquery) unless @metadatas
        @metadatas
      end
      def triples
        @triples = riquery(@triplesquery) unless @triples
        @triples
      end
    end
    class ContentObject < BaseObject
      include Cul::Fedora::Aggregator::ContentAggregator
      include Cul::Fedora::Objects
      attr :members
      def initialize(document, client)
        super
        gen_member_query(document)
      end
      def getsize
        if @size.nil?
          query = {:query=>@memberquery}
          query[:format] = 'count'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @size = res.to_i
        end
        @size
      end
      def getmembers
        if @members.nil?
          query = {:query=>@memberquery}
          query[:format] = 'json'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @members = JSON.parse(res)
        end
        @members
      end
    end
    class ImageObject < BaseObject
      include Cul::Fedora::Aggregator::ImageAggregator
      attr :members
      def initialize(document, client)
        super
        gen_member_query(document)
      end
      def getsize
        if @size.nil?
          query = {:query=>@memberquery}
          query[:format] = 'count'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @size = res.to_i
        end
        @size
      end
      def getmembers
        if @members.nil?
          query = {:query=>@memberquery}
          query[:format] = 'json'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @members = JSON.parse(res)
        end
        @members
      end
    end
  end
end
end
