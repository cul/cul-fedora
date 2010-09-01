require "helper"


class TestFedoraServer < Test::Unit::TestCase
  context "given  a fedora server" do
    setup do
      config = load_yaml_config("private/config.yml")
      @server = Cul::Fedora::Server.new(config[:fedora])
    end

    should "initialize properly" do
      assert @server
    end
  end
end

