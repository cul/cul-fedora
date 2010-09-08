require "helper"


class TestFedoraServer < Test::Unit::TestCase
  context "given  a fedora server" do

    setup do
      @config = YAML.load_file("private/config.yml")
      @examples = YAML.load_file("test/example_server_requests.yml")
      @riurl = @config["fedora"]["riurl"]
      @server = Server.new(@config["fedora"])
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

    should "be be able to generate paths out of sample requests" do
      @examples.each do |test|
        assert_equal @server.request_path(test["params"]), [@riurl + test["uri"], test["query"]]
      end

    end

    should "be able to make httpclient calls from sample requests" do
      mock_hc = mock()
      server_with_hc = Server.new(@config["fedora"].merge(:http_client => mock_hc))


      @examples.each do |test|
        mock_hc.expects(:get_content).with(@riurl + test["uri"], test["query"]).returns(nil)

        server_with_hc.request(test["params"])
      end
    end
  end
end

