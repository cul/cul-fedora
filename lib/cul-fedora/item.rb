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
        results = JSON::parse(@server.request(:method => "", :request => "risearch", :format => "json", :lang => "itql", :query => sprintf(@server.riquery, @pid)))["results"]

        results.collect { |r| @server.item(r["member"]) }

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

      def index_for_ac2
        results = Hash.new { |h,k| h[k] = [] }
        normalize_space = lambda { |s| s.to_s.strip.gsub(/\s{2,}/," ") }
        search_to_content = lambda { |x| x.kind_of?(Nokogiri::XML::Element) ? x.content : x.to_s }
        add_field = lambda { |name, value| results[name] << search_to_content.call(value) }

        get_fullname = lambda { |node| node.nil? ? nil : (node.css("mods|namePart[@type='family']").collect(&:content) | node.css("mods|namePart[@type='given']").collect(&:content)).join(", ") }

        roles = ["Author","author","Creator","Thesis Advisor","Collector","Owner","Speaker","Seminar Chairman","Secretary","Rapporteur","Committee Member","Degree Grantor","Moderator","Editor","Interviewee","Interviewer","Organizer of Meeting","Originator","Teacher"]

        raw = getIndex("raw")
        raw.root.add_namespace_definition("mods", "http://www.loc.gov/mods/v3")
        hierarchies = raw.at_css("index|hierarchies")
        collections = hierarchies.css("index|collection").collect(&:content)
        internals = hierarchies.css("index|internal").collect(&:content)
        mods = raw.at_css("index|description>mods|mods")
        return {} unless mods
        # baseline blacklight fields: id is the unique identifier, format determines by default, what partials get called
        add_field.call("id", @pid)
        internals.each do |internal|
          add_field.call("internal_h",  internal.to_s)
        end

        add_field.call("pid", @pid)
        collections.each do |collection|
          add_field.call("member_of", collection)
        end



        title = normalize_space.call(mods.css("mods|titleInfo>mods|nonSort,mods|title").collect(&:content).join(" "))
        add_field.call("title_display", title)
        add_field.call("title_search", title)

        all_names = []
        mods.css("mods|name[@type='personal']").each do |name_node|
          if name_node.css("mods|role>mods|roleTerm[@type='text']").collect(&:content).any? { |role| roles.include?(role) }

            fullname = get_fullname.call(name_node)

            all_names << fullname

            add_field.call("author_search", fullname.downcase)
            add_field.call("author_facet", fullname)

          end

        end

        add_field.call("authors_display",all_names.join("; "))
        add_field.call("date", mods.at_css("*[@keyDate='yes']"))

        mods.css("mods|genre").each do |genre_node|
          add_field.call("genre_facet", genre_node)
          add_field.call("genre_search", genre_node)

        end


        add_field.call("abstract", mods.at_css("mods|abstract"))
        add_field.call("handle", mods.at_css("mods|identifier[@type='hdl']"))

        mods.css("mods|subject:not([@authority='local'])>mods|topic").each do |topic_node|
          add_field.call("keyword_search", topic_node.content.downcase)
          add_field.call("keyword_facet", topic_node)
        end

        mods.css("mods|subject[@authority='local']>mods|topic").each do |topic_node|
          add_field.call("subject", topic_node)
          add_field.call("subject_search", topic_node)
        end


        add_field.call("tableOfContents", mods.at_css("mods|tableOfContents"))

        mods.css("mods|note").each { |note| add_field.call("notes", note) }

        if (related_host = mods.at_css("mods|relatedItem[@type='host']"))
          book_journal_title = related_host.at_css("mods|titleInfo>mods|title") 

          if book_journal_title
            book_journal_subtitle = mods.at_css("mods|name>mods|titleInfo>mods|subTitle")

            book_journal_title = book_journal_title.content + ": " + book_journal_subtitle.content.to_s if book_journal_subtitle

          end

          add_field.call("book_journal_title", book_journal_title)

          add_field.call("book_author", get_fullname.call(related_host.at_css("mods|name"))) 

          add_field.call("issn", related_host.at_css("mods|identifier[@type='issn']"))
        end

        add_field.call("publisher", mods.at_css("mods|relatedItem>mods|originInfo>mods|publisher"))
        add_field.call("publisher_location", mods.at_css("mods|relatedItem > mods|originInfo>mods|place>mods|placeTerm[@type='text']"))
        add_field.call("isbn", mods.at_css("mods|relatedItem>mods|identifier[@type='isbn']"))
        add_field.call("doi", mods.at_css("mods|identifier[@type='doi'][@displayLabel='Published version']"))

        mods.css("mods|physicalDescription>mods|internetMediaType").each { |mt| add_field.call("media_type_facet", mt) }

        mods.css("mods|typeOfResource").each { |tr| add_field.call("type_of_resource_facet", tr)}
        mods.css("mods|subject>mods|geographic").each do |geo|
          add_field.call("geographic_area", geo)
          add_field.call("geographic_area_search", geo)
        end





        listMembers.each_with_index do |member, i|
          add_field.call("ac.fulltext_#{i}", "")
        end

        return results
      end

      def to_s
        @pid
      end
    end
  end
end
