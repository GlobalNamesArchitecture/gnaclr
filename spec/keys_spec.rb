require "#{File.dirname(__FILE__)}/spec_helper"

describe Key do
  before(:each) do 
    @key = Key.new(:domain => "mydomain.org", :salt => Key.gen_salt)
  end

  specify 'should be valid' do
    @key.should be_valid
  end

  it 'should require a domain' do
    key = Key.new
    key.should_not be_valid
    key.errors[:domain].should_not be_nil
  end

end
