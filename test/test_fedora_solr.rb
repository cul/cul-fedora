require "helper"


class TestFedoraSolr < Test::Unit::TestCase
  context "given  a fedora server" do

    setup do
      @config = YAML.load_file("private/config.yml")
      @solr = Solr.new(@config["solr"])
    end

    should "require a url" do
      assert_raise ArgumentError do  
        Solr.new()
      end
    end

    should "initialize properly" do
      assert @solr
    end

  end
end


