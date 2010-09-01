require 'helper'

class TestFedoraItem < Test::Unit::TestCase
  context "given a fedora item" do
    setup do
      @fobj = Cul::Fedora::Item.new
    end

    should "initialize properly" do
      assert @fobj

    end


  end

end
