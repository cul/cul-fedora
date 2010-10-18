require 'nokogiri'
require 'rsolr-ext'

class SolrCollection
  attr_reader :pid, :solr
  def initialize(pid, solr_url)
    @pid = pid
    @solr = RSolr.connect :url=>solr_url
    @colon = Regexp.new(':')
  end
  def solr_query(query, start, rows, fl, collection_prefix=false)
    query_parms = {}
    query_parms[:q]=query
    query_parms[:start]=start
    query_parms[:rows]=rows
    query_parms[:fl]= "*"
    query_parms[:wt]= :ruby
    query_parms[:qt]= :document
    if (collection_prefix)
      query_parms[:facet]="on"
      query_parms["facet.field"]=:internal_h
      query_parms["facet.prefix"]=(collection_prefix + "*")
    end
    resp_json = solr.request('/select', query_parms)
    resp_json
  end
  def paths()
    if !(@paths)
      @paths = []
      response=solr_query("id:#{pid.gsub(@colon,'\:')}@*",0,1,"internal_h")
      if response["response"]["docs"][0]
        @paths |= response["response"]["docs"][0]["internal_h"]
      end
    end
    @paths
  end
  def paths=(arg1)
    @paths=arg1
  end
  def members()
    if !(@members)
      @members = []
      paths.each{|path|
        q = path.gsub(@colon,'\:')
        if q[0] = '/'
          q = q.slice(1,q.size - 1)
        end
        if q[-1] != '/'
          q = q + '/'
        end
        q = "internal_h:" + q
        p q
        size = 10
        start = 0
        while
          response=solr_query(q,start,size,:id)
          numFound = response["response"]["numFound"]
          docs = response["response"]["docs"] | []
          ids = docs.collect{|doc|
            p doc["id"]
            doc["id"].split('@')[0]
          }
          ids.compact!
          ids.uniq!
          @members |= ids
          start += size
          break if start > numFound
        end
      }
    end
    @members
  end
end
class Gatekeeper
  attr_reader :pids, :patterns
  def initialize(arg1)
    @pids = arg1
    @patterns = arg1.collect { |pid|
      Regexp.new('\b' + pid + '\b(\/)?')
    }
  end
  def allowed?(value)
    result = false
    patterns.each do |pattern|
      result |= (pattern =~ value)
    end
    result
  end
  def accept?(filedata)
    result = false
    if (patterns.length == 0)
      p "Warning: No allowable collection regex's"
    end
    doc = Nokogiri::XML::Document.parse(filedata,'utf-8')
    doc.xpath('//xmlns:field[@name="internal_h"]').each do |element|
      result |= allowed?element.content
    end
    result
  end
  def getInternalFacets(solr_url)
    # select_uri = base_uri + "/select"
    p solr_url
    results = []
    query_parms = {}
    query_parms[:q]="*:*"
    query_parms[:start]=0
    query_parms[:rows]=2
    query_parms[:facet]="on"
    query_parms["facet.field"]=[:internal_h]
    query_parms[:fl]= :internal_h
    query_parms[:wt]= :ruby
    query_parms[:qt]= :document
    solr = RSolr.connect :url=>solr_url
    colon = Regexp.new(':')
    pids.each { |pid|
      query_parms[:q]="id:#{pid.gsub(colon,'\:')}@*"
      facet_json = solr.request('/select', query_parms)
      #facet_json = solr.get('select', query_parms)
      p facet_json
      # parse it
      facets = facet_json
      # pull all internal_h values, and check against allowed patterns
      facet_counts = facets['facet_counts']['facet_fields']['internal_h']
      facet_counts.flatten!
      facet_counts.each_with_index { |val, index|
        if (val.to_s.index('path-')==0):
          results << facet_counts[index + 1] 
        end
      }
    }
      # return filtered values
    results
  end
end
namespace :solr do
 namespace :cul do
   namespace :fedora do
# for each collection, the task needs to fetch the unlimited count, and then work through the pages
# for development, we should probably just hard-code a sheet of data urls
     desc "load the fedora configuration"
     task :configure => :environment do
       env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
       yaml = YAML::load(File.open("config/fedora.yml"))[env]
       ENV['RI_URL'] ||= yaml['riurl'] 
       ENV['RI_QUERY'] ||= yaml['riquery'] 
       ALLOWED = Gatekeeper.new(yaml['collections'].split(';'))
     end

     desc "index objects from a CUL fedora repository"
     task :index => :configure do
       urls_to_scan = case
       when ENV['URL_LIST']
         url = ENV['URL_LIST']
         uri = URI.parse(url) # where is url assigned?
         url_list = Net::HTTP.new(uri.host, uri.port)
         url_list.use_ssl = uri.scheme == 'https'
         urls = url_list.start { |http| http.get(uri.path).body }
         url_list.finish
         urls
       when ENV['COLLECTION_PID']
         solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
         collection = SolrCollection.new(ENV['COLLECTION_PID'],solr_url)
         facet_vals = collection.paths.find_all { |val|
           ALLOWED.allowed?val
         }
         facet_vals = facet_vals.reject{|val|
           facet_vals.any?{|compare|
             (val != compare && val.index(compare) == 0)
           }
         }
         collection.paths=facet_vals
         query = "format=json&lang=itql&query=" + URI.escape(sprintf(ENV['RI_QUERY'],ENV['COLLECTION_PID']))
         fedora_uri = URI.parse(ENV['RI_URL'])
         risearch = Net::HTTP.new(fedora_uri.host, fedora_uri.port)
         risearch.use_ssl = fedora_uri.scheme.eql? "https"
         risearch.start
         members = risearch.post(fedora_uri.path + '/risearch',query)
         risearch.finish
         members = JSON::parse(members.body)['results']
         members = members.collect {|member|
           member['member'].split('/')[1]
         }
         members |= collection.members
         url_array = members.collect {|member| fedora_uri.merge('/fedora/get/' + member + '/ldpd:sdef.Core/getIndex?profile=scv').to_s}
       when ENV['PID']
         pid = ENV['PID']
         fedora_uri = URI.parse(ENV['RI_URL'])
         url_array = [ fedora_uri.merge('/fedora/get/' + pid + '/ldpd:sdef.Core/getIndex?profile=scv').to_s]
       when ENV['SAMPLE_DATA']
         File.read(File.join(RAILS_ROOT,"test","sample_data","cul_fedora_index.json"))
       else
         p "No input options given!"
         url_array = []
       end

       url_array ||= JSON::parse(urls_to_scan)
       puts "#{url_array.size} URLs to scan."

       successes = 0

       solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
       puts "Using Solr at: #{solr_url}"
       
       update_uri = URI.parse(solr_url.gsub(/\/$/, "") + "/update")

       url_array.each do |source_url|
         source_uri = URI.parse(source_url)
         begin
           source = Net::HTTP.new(source_uri.host, source_uri.port)
           source.use_ssl = source_uri.scheme.eql? "https"
           source.start
           res =  source.get(source_uri.path+'?profile=scv')
           source.finish
           if res.response.code == "200" && ALLOWED.accept?(res.body)
             Net::HTTP.start(update_uri.host, update_uri.port) do |http|
               hdrs = {'Content-Type'=>'text/xml','Content-Length'=>res.body.length.to_s}
               begin
                  update_res = http.post(update_uri.path, res.body, hdrs)
                  if update_res.response.code == "200"
                     successes += 1
                  else
                     puts "#{update_uri} received: #{update_res.response.code}"
                     puts "#{update_uri} msg: #{update_res.response.message}"
                     puts "\t#{source_uri}"
                  end
               rescue Exception => e
                  puts "#{update_uri} threw error #{e.message}"
               end
             end

           else
             if res.response.code == "200"
               puts "#{source_url} rejected: no allowable collection in hierarchy"
             else
               puts "#{source_url} received: #{res.response.code}"
             end
           end
         rescue Exception => e
           puts "#{source_url} threw error #{e.message}"
         end

       end

       puts "#{successes} URLs scanned successfully."
       if (successes > 0)
             Net::HTTP.start(update_uri.host, update_uri.port) do |http|
               msg = '<commit waitFlush="false" waitSearcher="false"></commit>'
               hdrs = {'Content-Type'=>'text/xml','Content-Length'=>msg.length.to_s}
               begin
                  commit_res = http.post(update_uri.path, msg, hdrs)
                  if commit_res.response.code == "200"
                     puts 'commit successful'
                  else
                     puts "#{update_uri} received: #{commit_res.response.code}"
                     puts "#{update_uri} msg: #{commit_res.response.message}"
                  end
               rescue Exception => e
               end
             end
       end
     end
   end
 end
end
