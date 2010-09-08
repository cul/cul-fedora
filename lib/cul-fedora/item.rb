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

      def request(options = {})
        @server.request(options.merge(:pid => @pid))
      end

      def request_path(options = {})
        @server.request_path(options.merge(:pid => @pid))
      end

      def getIndex(profile = "raw")
        Nokogiri::XML(request(:request => "getIndex", :sdef => "ldpd:sdef.Core", :profile => profile))
      end

      def datastream(name)
        request(:request => name.to_s.upcase)
      end

      def listMembers
        begin
          result = request(:request => "listMembers", :sdef => "ldpd:sdef.Aggregator", :format => "", :max => "", :start => "")

          Nokogiri::XML(result).css("sparql>results>result>member").collect do |member|
            @server.item(member.attributes["uri"].value)
          end
        rescue
          []
        end
      end

      def describedBy
        begin
          result = request(:request => "describedBy", :sdef => "ldpd:sdef.Core")
          Nokogiri::XML(result).css("sparql>results>result>description").collect do |metadata|
            @server.item(metadata.attributes["uri"].value)
          end
        rescue
          []
        end
      end

      def belongsTo
        begin
          result = Nokogiri::XML(datastream("RELS-EXT"))
          result.xpath("/rdf:RDF/rdf:Description/*[local-name()='memberOf']").collect do |member|
            @server.item(member.attributes["resource"].value)
          end
        rescue
          []
        end
      end

      def ac2_solr_doc
        normalize_space = lambda { |s| s.to_s.strip.gsub(/\s{2,}/," ") }
        search_to_content = lambda { |x| x.kind_of?(Nokogiri::XML::Element) ? x.content : x.to_s }
        add_field = lambda { |x, name, value| x.field(:name => name) { x.text search_to_content.call(value) }}

        get_fullname = lambda { |node| node.nil? ? nil : (node.css("namePart[@type='family']").collect(&:content) | node.css("namePart[@type='given']").collect(&:content)).join(", ") }

        roles = ["Author","author","Creator","Thesis Advisor","Collector","Owner","Speaker","Seminar Chairman","Secretary","Rapporteur","Committee Member","Degree Grantor","Moderator","Editor","Interviewee","Interviewer","Organizer of Meeting","Originator","Teacher"]

        collections = self.belongsTo
        meta = describedBy.first

        meta = Nokogiri::XML(meta.datastream("CONTENT")) if meta

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.doc_ {
            # baseline blacklight fields: id is the unique identifier, format determines by default, what partials get called
            add_field.call(xml, "id", @pid)
            add_field.call(xml, "internal_h",  collections.first.to_s + "/")

             collections.each do |collection|
            add_field.call(xml, "member_of", collection)
          end
          
          
          if (meta && mods = meta.css("mods"))
            title = normalize_space.call(mods.css("titleInfo>nonSort,title").collect(&:content).join(" "))
            add_field.call(xml, "title_display", title)
            add_field.call(xml, "title_search", title)
         
            all_names = []
            mods.css("name[@type='personal']").each do |name_node|
              if name_node.css("role>roleTerm[@type='text']").collect(&:content).any? { |role| roles.include?(role) }
                
                fullname = get_fullname.call(name_node)
                
                all_names << fullname
                
                add_field.call(xml, "author_search", fullname.downcase)
                add_field.call(xml, "author_facet", fullname)

              end
              
            end

            add_field.call(xml, "authors_display",all_names.join("; "))
            add_field.call(xml, "date", mods.at_css("*[@keyDate='yes']"))

            mods.css("genre").each do |genre_node|
              add_field.call(xml, "genre_facet", genre_node)
              add_field.call(xml, "genre_search", genre_node)

            end
              

            add_field.call(xml, "abstract", mods.at_css("abstract"))
            add_field.call(xml, "handle", mods.at_css("identifier[@type='hdl']"))
         
            mods.css("subject:not([@authority='local'])>topic").each do |topic_node|
              add_field.call(xml, "keyword_search", topic_node.content.downcase)
              add_field.call(xml, "keyword_facet", topic_node)
            end

            mods.css("subject[@authority='local']>topic").each do |topic_node|
              add_field.call(xml, "subject", topic_node)
              add_field.call(xml, "subject_search", topic_node)
            end


            add_field.call(xml, "tableOfContents", mods.at_css("tableOfContents"))
            
            mods.css("note").each { |note| add_field.call(xml, "notes", note) }
            
            if (related_host = mods.at_css("relatedItem[@type='host']"))
              book_journal_title = related_host.at_css("titleInfo>title") 

              if book_journal_title
                book_journal_subtitle = mods.at_css("name>titleInfo>subTitle")
                
                book_journal_title = book_journal_title.content + ": " + book_journal_subtitle.content.to_s if book_journal_subtitle

              end

              add_field.call(xml, "book_journal_title", book_journal_title)

              add_field.call(xml, "book_author", get_fullname.call(related_host.at_css("name"))) 
  
              add_field.call(xml, "issn", related_host.at_css("identifier[@type='issn']"))
            end

            add_field.call(xml, "publisher", mods.at_css("relatedItem>originInfo>publisher"))
            add_field.call(xml, "publisher_location", mods.at_css("relatedItem > originInfo>place>placeTerm[@type='text']"))
            add_field.call(xml, "isbn", mods.at_css("relatedItem>identifier[@type='isbn']"))
            add_field.call(xml, "doi", mods.at_css("identifier[@type='doi'][@displayLabel='Published version']"))
            
            mods.css("physicalDescription>internetMediaType").each { |mt| add_field.call(xml, "media_type_facet", mt) }

            mods.css("typeOfResource").each { |tr| add_field.call(xml, "type_of_resource_facet", tr)}
            mods.css("subject>geographic").each do |geo|
              add_field.call(xml, "geographic_area", geo)
              add_field.call(xml, "geographic_area_search", geo)
            end


            
          end

          listMembers.each_with_index do |member, i|
            add_field.call(xml, "ac.fulltext_#{i}", "")
          end

          
          
          }
        end

        return builder.to_xml.sub('<?xml version="1.0"?>',"")
      end

      def to_s
        @pid
      end
    end
  end
end
