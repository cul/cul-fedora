require "helper"

class TestFedoraItem < Test::Unit::TestCase
  context "given a server" do
    setup do
      config = YAML.load_file("private/config.yml")
      @server = Server.new(config["fedora"])
      @item = Item.new(@server, "info:fedora/ac:3")
    end

    should "initialize properly with a server and pid" do
      assert @item

    end

    should "require a server and pid" do
      assert_raise ArgumentError do 
        Item.new(@server)
      end
    end

    should "properly parse uris into pids" do
      assert_equal @item.pid, "ac:3"
      assert_equal Item.new(@server, "ac:5").pid, "ac:5"

    end

    should "be able to compare" do
      assert_equal Item.new(@server, "info:fedora/ac:3"), Item.new(@server, "info:fedora/ac:3")
      assert_equal Item.new(@server, "ac:3"), Item.new(@server, "info:fedora/ac:3")
    end


  end

end
