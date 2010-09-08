require "helper"

class TestFedoraItem < Test::Unit::TestCase
  context "given a server" do
    setup do
      @config = YAML.load_file("private/config.yml")
      @riurl = @config["fedora"]["riurl"]
      @hc = HTTPClient.new()
      @server = Server.new(@config["fedora"].merge(:http_client => @hc))
      @item = Item.new(:server => @server, :uri => "info:fedora/ac:3")
    end

    should "initialize properly with a server and pid" do
      assert @item

    end

    should "initialize properly with a server config and pid" do
      assert Item.new(:server_config => @config["fedora"], :uri => "info:fedora/ac:3")
    end

    should "require a server and pid" do
      assert_raise ArgumentError do 
        Item.new(:server => @server)
      end
    end

    should "properly parse uris into pids" do
      assert_equal @item.pid, "ac:3"
      assert_equal Item.new(:server => @server, :pid => "ac:5").pid, "ac:5"

    end

    should "be able to compare" do
     
      assert_equal @item, Item.new(:server => @server, :pid => "ac:3")
      assert_equal @item, Item.new(:server => @server, :uri => "info:fedora/ac:3")
      assert_equal @item, Item.new(:server_config => @config["fedora"], :pid => "ac:3")
    end


    should "be able to make requests" do

      @server.expects(:request).with(:pid => "ac:3", :request => "RELS-EXT")

      @item.request(:request => "RELS-EXT")
    end

    should "be able to call getIndex" do
      @hc.expects(:get_content).with(@riurl + "/get/ac:3/ldpd:sdef.Core/getIndex", :profile => "raw").returns(nil)

      @item.getIndex("raw")
    end


    context "and an academic commons object" do
      setup do
        @get_index = Nokogiri::XML(File.read("test/data/125467_get_index.xml"))
        @solr_doc = Nokogiri::XML(File.read("test/data/125467_solr_doc.xml"))
      end

      should "be able to generate a solr doc" do
        

      end

    end

  end

  

end
