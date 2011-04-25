require "open3"

module Cul
  module Fedora
    class Item
      attr_reader :server, :pid
      include Open3 

      URI_TO_PID = 'info:fedora/'


      def <=>(other)
        pid <=> other.pid
      end

      def pid_escaped
        pid.gsub(/:/,'\\:')
      end

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


      def risearch_for_members()
        results = JSON::parse(@server.request(:method => "", :request => "risearch", :format => "json", :lang => "itql", :query => sprintf(@server.riquery, @pid)))["results"]

        results.collect { |r| @server.item(r["member"]) }

      end

      def listMembers()
        begin
          result = Nokogiri::XML(request(:method => "/objects", :sdef => "methods/ldpd:sdef.Aggregator", :request => "listMembers", :format => "", :max => "", :start => ""))

          result.css("sparql>results>result>member").collect do |result_node|
            @server.item(result_node.attributes["uri"].value)
          end
        rescue
          []
        end
      end

      def describedBy
        begin
          params = {:method => '/objects', :request => "describedBy", :sdef => "methods/ldpd:sdef.Core"}
          result = request(params)
          Nokogiri::XML(result).css("sparql>results>result>description").collect do |metadata|
            @server.item(metadata.attributes["uri"].value)
          end
        rescue Exception => e
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

      def index_for_ac2(options = {})
        do_fulltext = options[:fulltext] || false
        do_metadata = options[:metadata] || true

        status = :success
        error_message = ""


        results = Hash.new { |h,k| h[k] = [] }
        normalize_space = lambda { |s| s.to_s.strip.gsub(/\s{2,}/," ") }
        search_to_content = lambda { |x| x.kind_of?(Nokogiri::XML::Element) ? x.content : x.to_s }
        add_field = lambda { |name, value| results[name] << search_to_content.call(value) }

        get_fullname = lambda { |node| node.nil? ? nil : (node.css("namePart[@type='family']").collect(&:content) | node.css("namePart[@type='given']").collect(&:content)).join(", ") }

        roles = ["Author","author","Creator","Thesis Advisor","Collector","Owner","Speaker","Seminar Chairman","Secretary","Rapporteur","Committee Member","Degree Grantor","Moderator","Editor","Interviewee","Interviewer","Organizer of Meeting","Originator","Teacher"]


        begin
          collections = self.belongsTo
          meta = describedBy.first

          meta = Nokogiri::XML(meta.datastream("CONTENT")) if meta
          mods = meta.at_css("mods") if meta

          if mods && do_metadata
            # baseline blacklight fields: id is the unique identifier, format determines by default, what partials get called
            add_field.call("id", @pid)
            add_field.call("internal_h",  collections.first.to_s + "/")
            add_field.call("pid", @pid)
            collections.each do |collection|
              add_field.call("member_of", collection)
            end



            title = normalize_space.call(mods.css("titleInfo>nonSort,title").collect(&:content).join(" "))
            record_creation_date = mods.at_css("recordInfo>recordCreationDate").text.gsub("UTC", "").strip
            if(!record_creation_date.nil? || !record_creation_date.empty?)
              record_creation_date = DateTime.parse(record_creation_date)
              add_field.call("record_creation_date", record_creation_date.strftime("%Y-%m-%dT%H:%M:%SZ"))
            end
            add_field.call("title_display", title)
            add_field.call("title_search", title)

            all_names = []
            mods.css("name[@type='personal']").each do |name_node|
              if name_node.css("role>roleTerm[@type='text']").collect(&:content).any? { |role| roles.include?(role) }

                fullname = get_fullname.call(name_node)

                all_names << fullname
                add_field.call("author_id_uni", name_node.at_css("authorID[@type='institution']"))
                add_field.call("author_id_repository", name_node.at_css("authorID[@type='repository']"))
                add_field.call("author_id_naf", name_node.at_css("authorID[@type='naf']"))
                add_field.call("author_search", fullname.downcase)
                add_field.call("author_facet", fullname)

              end

            end

            add_field.call("authors_display",all_names.join("; "))
            add_field.call("date", mods.at_css("*[@keyDate='yes']"))

            mods.css("genre").each do |genre_node|
              add_field.call("genre_facet", genre_node)
              add_field.call("genre_search", genre_node)

            end


            add_field.call("abstract", mods.at_css("abstract"))
            add_field.call("handle", mods.at_css("identifier[@type='hdl']"))

            mods.css("subject:not([@authority='local'])>topic").each do |topic_node|
              add_field.call("keyword_search", topic_node.content.downcase)
              add_field.call("keyword_facet", topic_node)
            end

            mods.css("subject[@authority='local']>topic").each do |topic_node|
              add_field.call("subject", topic_node)
              add_field.call("subject_search", topic_node)
            end


            add_field.call("tableOfContents", mods.at_css("tableOfContents"))

            mods.css("note").each { |note| add_field.call("notes", note) }

            if (related_host = mods.at_css("relatedItem[@type='host']"))
              book_journal_title = related_host.at_css("titleInfo>title") 

              if book_journal_title
                book_journal_subtitle = mods.at_css("name>titleInfo>subTitle")

                book_journal_title = book_journal_title.content + ": " + book_journal_subtitle.content.to_s if book_journal_subtitle

              end

              add_field.call("book_journal_title", book_journal_title)

              add_field.call("book_author", get_fullname.call(related_host.at_css("name"))) 

              add_field.call("issn", related_host.at_css("identifier[@type='issn']"))
            end

            add_field.call("publisher", mods.at_css("relatedItem>originInfo>publisher"))
            add_field.call("publisher_location", mods.at_css("relatedItem > originInfo>place>placeTerm[@type='text']"))
            add_field.call("isbn", mods.at_css("relatedItem>identifier[@type='isbn']"))
            add_field.call("doi", mods.at_css("identifier[@type='doi'][@displayLabel='Published version']"))

            mods.css("physicalDescription>internetMediaType").each { |mt| add_field.call("media_type_facet", mt) }

            mods.css("typeOfResource").each { |tr| add_field.call("type_of_resource_facet", tr)}
            mods.css("subject>geographic").each do |geo|
              add_field.call("geographic_area", geo)
              add_field.call("geographic_area_search", geo)
            end

            add_field.call("export_as_mla_citation_txt","test")
          end


          if do_fulltext 
            listMembers.each_with_index do |member, i|
              tika_directory = File.expand_path(File.join(File.expand_path(File.dirname(__FILE__)), "..", "tika"))

              resource_file_name = File.join(tika_directory, "scratch", Time.now.to_i.to_s + "_" + rand(10000000).to_s)
              tika_jar = File.join(tika_directory, "tika-0.3.jar")

              File.open(resource_file_name, "w") { |f| f.puts(member.datastream("CONTENT")) }


              tika_result = []
              tika_error = []

              Open3.popen3("java -jar #{tika_jar} -t #{resource_file_name}") do |stdin, stdout, stderr|
                tika_result = stdout.readlines
                tika_error = stderr.readlines
              end

              unless tika_error.empty?
                status = :error
                error_message += tika_error.join("\n")
              else


                add_field.call("ac.fulltext_#{i}", tika_result)
              end

              File.delete(resource_file_name)
            
            
            
            end



          end

        rescue Exception => e
          status = :error
          error_message += e.message
        end

        status = :invalid_format  if results.empty?

        return {:status => status, :error_message => error_message, :results => results}

      end



      def to_s
        @pid
      end
    end
  end
end
