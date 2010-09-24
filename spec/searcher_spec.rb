require "#{File.dirname(__FILE__)}/spec_helper"

describe Gnaclr::Searcher do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end

  before(:all) do
    @params = {
      :page => '10',
      :per_page => '5',
      :format => 'json',
      :show_revisions => 'true',
      :search_term => 'something',
    }
    @meta = Gnaclr::ClassificationMetadataSearcher.new
    @sci = Gnaclr::ScientificNameSearcher.new
    @vern = Gnaclr::VernacularNameSearcher.new
    @meta_search = Gnaclr::Searcher.new(@meta)
    @sci_search = Gnaclr::Searcher.new(@sci)
    @vern_search = Gnaclr::Searcher.new(@vern)
  end


  it "should initialize with 3 engines" do
    lambda do
      Gnaclr::Searcher.new(@meta)
      Gnaclr::Searcher.new(@sci)
      Gnaclr::Searcher.new(@vern)
    end.should_not raise_error

    lambda { Gnaclr::Searcher.new(1) }.should raise_error
  end
  
  it "should have common behavior for all search types" do
    [@meta_search, @sci_search, @vern_search].each do |s|
      params = @params.clone
      s.args = params 
      s.args.should == { :per_page => 5, :format => "json", :callback => nil, :show_revisions => true, :search_term => "something", :page => 10 }
      params = { :per_page => nil, :show_revisions => 'not_true', :format => 'any', :search_term => nil, :page => nil }
      s.args = params
      s.args.should == { :per_page => 30, :format => nil, :callback => nil, :show_revisions => false, :search_term => "", :page => 1 }
      s.search_raw == [[],0] #empty string returns empty search
    end
  end

  it "should search all search methods" do
    post('/classifications', :file => Rack::Test::UploadedFile.new(FILE1_1, 'application/gzip'), :uuid => UUID1)
    params = @params.clone
    params.merge!(:search_term => 'Classification', :page => 1, :format => 'xml' )
    $yaya = 1
    res, format = Gnaclr::Searcher.search_all(params)
    format.should == 'xml'
    res.key?(:scientific_name).should be_true
    res.key?(:vernacular_name).should be_true
    res.key?(:classification_metadata).should be_true
  end

  it "should perform classification metadata search" do
    post('/classifications', :file => Rack::Test::UploadedFile.new(FILE1_1, 'application/gzip'), :uuid => UUID1)
    params = @params.clone
    params.merge!(:search_term => 'Classification', :page => 1 )
    @meta_search.args = params
    res = @meta_search.search_raw
    res[0].size.should == 1
    res[1].should == 1
    res = @meta_search.search
    res.is_a?(Hash).should be_true
    res.empty?.should be_false
  end

  it "should perform solr searches" do
    post('/classifications', :file => Rack::Test::UploadedFile.new(FILE1_1, 'application/gzip'), :uuid => UUID1)
    params = @params.clone
    params.merge!(:search_term => 'Grass flies', :page => 1 )
    @vern_search.args = params
    res = @vern_search.search_raw
    res[0].size.should == 1
    res[1].should == 1
    res = @vern_search.search
    res.is_a?(Hash).should be_true
    res.empty?.should be_false
    res[:classifications][0][:path].should == "Leptogastrinae"
    params.merge!(:search_term => 'Leptogaster weslacensis', :page => 1 )
    @sci_search.args = params
    res = @sci_search.search_raw
    res[0].size.should == 1
    res[1].should == 1
    res = @sci_search.search
    res.is_a?(Hash).should be_true
    res.empty?.should be_false
    res[:classifications][0][:path].should == "Leptogastrinae|Leptogastrini|Apachekolos|Apachekolos weslacensis"
    res[:classifications][0][:found_as] == 'synonym'
  end

end
