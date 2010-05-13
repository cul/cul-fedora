
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
         query = "format=json&lang=itql&query=" + URI.escape(sprintf(ENV['RI_QUERY'],ENV['COLLECTION_PID']))
         fedora_uri = URI.parse(ENV['RI_URL'])
         risearch = Net::HTTP.new(fedora_uri.host, fedora_uri.port)
         risearch.use_ssl = fedora_uri.scheme.eql? "https"
         risearch.start
         members = risearch.post(fedora_uri.path + '/risearch',query)
         risearch.finish
         members = JSON::parse(members.body)['results']
         url_array = members.collect {|member| fedora_uri.merge('/fedora/get/' + member['member'].split('/')[1] + '/ldpd:sdef.Core/getIndex').to_s}
       when ENV['PID']
         pid = ENV['PID']
         fedora_uri = URI.parse(ENV['RI_URL'])
         url_array = [ fedora_uri.merge('/fedora/get/' + pid + '/ldpd:sdef.Core/getIndex').to_s]
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
           res =  source.get(source_uri.path)
           source.finish
           if res.response.code == "200"
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
             puts "#{source_url} received: #{res.response.code}"
           end
         rescue Exception => e
           puts "#{source_url} threw error #{e.message}"
         end

       end

       puts "#{successes} URLs scanned successfully."
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
