namespace :solr do
  namespace :cul do
    namespace :fedora do
      desc "index objects from a CUL fedora repository"
      task :index => :environment do
        urls_to_scan = if ENV['URL_LIST']
          uri = URI.parse(url)
          Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path).body }
        else
          File.read(File.join(RAILS_ROOT,"test","sample_data","cul_fedora_index.json"))
        end
        
        url_array = JSON::parse(urls_to_scan)
        puts "#{url_array.size} URLs to scan."
        
        successes = 0
        
        solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
        update_uri = URI.parse(solr_url.gsub(/\/$/, "") + "/update")
        
        url_array.each do |source_url|
          source_uri = URI.parse(source_url)
          begin
            res = Net::HTTP.start(source_uri.host, source_uri.port) { |http| http.get(source_uri.path) }
            if res.response.code == "200"
              Net::HTTP.start(update_uri.host, update_uri.port) do |http|
                http.post(update_uri.path, res.body)
              end

              successes += 1
            else
              puts "#{source_url} received: #{res.response.code}"
            end
          rescue Exception => e
            puts "#{source_url} threw error #{e.message}"
          end
          
        end
        
        puts "#{successes} URLs scanned successfully."
      end
    end
  end
end