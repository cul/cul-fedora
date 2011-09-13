require "httpclient"
require "nokogiri"
begin
  require "active_support"
rescue
  require "activesupport"
end
require "rsolr"
require "rsolr-ext"
require "open3"
require "logger"

require "cul-fedora/item"
require "cul-fedora/server"
require "cul-fedora/solr"
