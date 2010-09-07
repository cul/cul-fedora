require "helper"


class TestFedoraServer < Test::Unit::TestCase
  context "given  a fedora server" do
    CONFIG = YAML.load_file("private/config.yml")
    URI_EXAMPLES = YAML.load_file("test/example_server_requests.yml")

    setup do




      @riurl = CONFIG["fedora"]["riurl"]


      @server = Server.new(CONFIG["fedora"])
    end

    should "require a riurl" do
      assert_raise ArgumentError do  
        Server.new()
      end
    end

    should "initialize properly" do
      assert @server
    end

    should "be able to create an item from a uri or pid" do
      item = Item.new(@server, "ac:4")

      assert_equal @server.item("ac:4"),  item
      assert_equal @server.item("info:fedora/ac:4"), item

    end

    context "and a list of sample requests" do

      should "be be able to generate urls to methods" do
        URI_EXAMPLES.each do |test|
          puts test.inspect

        end

      end


      should "be able to create urls to various methods" do
        riurl = CONFIG["fedora"]["riurl"]
        assert_equal @server.request_path(:request => "RELS-EXT", :pid => "ac:4"),
          [riurl + "/get/ac:4/RELS-EXT", {}] 
        
        assert_equal @server.request_path(:request => "listMembers", :pid => "ac:5", :sdef => "ldpd:sdef.Aggregator"),
          [riurl + "/get/ac:5/ldpd:sdef.Aggregator/listMembers", {}]

        assert_equal @server.request_path(:request => "getIndex", :pid => "ac:6", :sdef => "ldpd:sdef.Core", :format => "raw"),
          [riurl + "/get/ac:6/ldpd:sdef.Core/getIndex", {:format => "raw"}]

      end
    end
  end
end

