
namespace :solr do
 namespace :cul do
   namespace :fedora do
# for each collection, the task needs to fetch the unlimited count, and then work through the pages
# for development, we should probably just hard-code a sheet of data urls
     desc "index objects from a CUL fedora repository"
     task :index => :environment do
       urls_to_scan = if ENV['URL_LIST']
         url = ENV['URL_LIST']
         uri = URI.parse(url) # where is url assigned?
         Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path).body }
       else
         File.read(File.join(RAILS_ROOT,"test","sample_data","cul_fedora_index.json"))
       end

       url_array = JSON::parse(urls_to_scan)
       puts "#{url_array.size} URLs to scan."

       successes = 0

       solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
       puts "Using Solr at: #{solr_url}"
       
       update_uri = URI.parse(solr_url.gsub(/\/$/, "") + "/update")

       url_array.each do |source_url|
         source_uri = URI.parse(source_url)
         begin
           res = Net::HTTP.start(source_uri.host, source_uri.port) { |http| http.get(source_uri.path) }
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
