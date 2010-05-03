require "#{File.dirname(__FILE__)}/spec_helper"

describe Classification do
  describe "#new" do
    before(:all) do 
      @uuid = UUID1
    end

    it "should generate new classification" do
      file1 = FILE1_1
      c = Classification.new(@uuid, file1)
      c.uuid.should == uuid
    end
  end
end
