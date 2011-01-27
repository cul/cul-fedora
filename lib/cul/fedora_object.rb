module Cul
module Fedora
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
       @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_t].first)
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
       @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_t].first)
       @memberquery
     end
   end
  end
  end
  module Objects
    class BaseObject
      def initialize(document)
        @riurl = FEDORA_CONFIG[:riurl] + '/risearch'
        @metadataquery = Cul::Fedora::Aggregator::DESCRIPTION_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_t].first)
      end
      def getmetadatalist
        if @metadatas.nil?
          hc = HTTPClient.new
          query = {:query=>@metadataquery}
          query[:format] = 'json'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = hc.get_content(@riurl,query)
          @metadatas = JSON.parse(res)["results"]
        end
        @metadatas
      end
    end
    class ContentObject
      include Cul::Fedora::Aggregator::ContentAggregator
      include Cul::Fedora::Objects
      attr :members
      def initialize(document)
        @riurl = FEDORA_CONFIG[:riurl] + '/risearch'
        gen_member_query(document)
      end
      def getsize
        if @size.nil?
          hc = HTTPClient.new
          query = {:query=>@memberquery}
          query[:format] = 'count'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = hc.get_content(@riurl,query)
          @size = res.to_i
        end
        @size
      end
      def getmembers
        if @members.nil?
          hc = HTTPClient.new
          query = {:query=>@memberquery}
          query[:format] = 'json'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = hc.get_content(@riurl,query)
          @members = JSON.parse(res)
        end
        @members
      end
    end
    class ImageObject
      include Cul::Fedora::Aggregator::ImageAggregator
      attr :members
      def initialize(document)
        @riurl = FEDORA_CONFIG[:riurl] + '/risearch'
        gen_member_query(document)
      end
      def getsize
        if @size.nil?
          hc = HTTPClient.new
          query = {:query=>@memberquery}
          query[:format] = 'count'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = hc.get_content(@riurl,query)
          @size = res.to_i
        end
        @size
      end
      def getmembers
        if @members.nil?
          hc = HTTPClient.new
          query = {:query=>@memberquery}
          query[:format] = 'json'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = hc.get_content(@riurl,query)
          @members = JSON.parse(res)
        end
        @members
      end
    end
  end
end
end
