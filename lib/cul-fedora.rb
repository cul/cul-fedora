require "httpclient"
require "nokogiri"
begin
	require "activesupport"
rescue LoadError
	require "active_support"
end
require "rsolr"
require "rsolr-ext"
require "open3"
require "logger"

require "cul-fedora/item"
require "cul-fedora/server"
require "cul-fedora/solr"
