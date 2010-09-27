Given /^UUID "([^"]*)"$/ do |uuid|
  @uuid = uuid
end

Given /^no classification with the UUID$/ do
  Classification.first(:uuid => @uuis).should be_nil
end

Given /^a "([^"]*)" local file$/ do |file_name|
  @file = File.join(SiteConfig.root_path, 'spec', 'files',  file_name)
  File.exist?(@file).should be_true
end

When /^I upload the file through the API$/ do
  @classification_count = Classification.count
  post('/classifications', :file => Rack::Test::UploadedFile.new(@file, 'applicaation/gzip'), :uuid => @uuid)
  @classification = Classification.first(:uuid => @uuid)
end

Then /^classification will be added$/ do
  Classification.first(:uuid => @uuid).class.should == Classification
  Classification.count.should == @classification_count + 1
end

Then /^the file will be saved for public access$/ do
  file = File.split(@file).last
  file = File.join(SiteConfig.root_path, 'public', 'files', @uuid, file)
  File.exists?(file).should be_true
end

Given /^a classification with the UUID$/ do
  Given %{a "data_v1.tar.gz" local file}
  And %{I upload the file through the API}
  cl = Classification.first(:uuid => @uuid)
  cl.class.should == Classification
  @title = cl.title
end

Given /^several revisions of a classification with the UUID$/ do
  Given %{a "data_v1.tar.gz" local file}
  And %{I upload the file through the API}
  And %{a "data_v2.tar.gz" local file}
  And %{I upload the file through the API}
end

Then /^classification will be updated$/ do
  cl = Classification.first(:uuid => @uuid)
  cl.title.should_not == @title
end

Then /^old revision will still be accessible$/ do
  repository = Grit::Repo.new(File.join(SiteConfig.files_path, @uuid))
  names =  repository.commits.map {|c| c.tree.blobs.first.name}
  names.sort.should == ['data_v1.tar.gz', 'data_v2.tar.gz']
end

Then /^the file should be rejected$/ do
  Classification.count.should == @classification_count
end

When /^I search for "([^"]*)" using API$/ do |search_term|
  @search_term = search_term
  @response = {}
  ['xml', 'json'].each do |format|
    visit("/search?search_term=Classification&format=#{format}")
    @response[format.to_sym] = body
  end
end

Then /^I find json data about this classification$/ do
  res = JSON.parse(@response[:json], :symbolize_names => true)
  c = res[:classification_metadata_search] ? res[:classification_metadata_search][:classifications][0] : res
  search_fields = [c[:title], c[:authors].map {|a| a[:last_name] + ' ' + a[:first_name]}, c[:description]].flatten.join(' ')
  search_fields.match(/#{@search_term}/).should_not be_nil
end

Then /^I find xml data about this classification$/ do
  res = Crack::XML.parse(@response[:xml])
  c = res['hash']['classification_metadata_search'] ? res['hash']['classification_metadata_search']['classifications'][0] : res['hash']
  search_fields = [c['title'], c['authors'].map {|a| a['last_name'] + ' ' + a['first_name']}, c['description']].flatten.join(' ')
  search_fields.match(/#{@search_term}/).should_not be_nil 
end

When /^I search for "([^"]*)" using API with revisions flag$/ do |search_term|
  @search_term = search_term
  @response = {}
  ['xml', 'json'].each do |format|
    visit("/search?search_term=Classification&format=#{format}&show_revisions=true")
    @response[format.to_sym] = body
  end
end

Then /^I get data about revisions$/ do
  res = Crack::JSON.parse @response[:json]
  c = res['classifications'] ? res['classifications'][0] : res
  c.size.should > 1
end

When /^I query API for the classification with the id$/ do
  @response = {}
  ['xml', 'json'].each do |format|
    visit("/classification/#{@classification.id}?format=#{format}")
    @response[format.to_sym] = body
  end
end

Then /^I get "([^"]*)" data about this classification$/ do |arg1|
  ['xml', 'json'].each do |format|
    visit("/classifications?format=#{format}")
    @response[format.to_sym] = body
  end
end

Then /^I find no classifications$/ do
  res = Crack::XML.parse(@response[:xml])
  res['hash']['classification_metadata_search']['classifications'].size == 0
end

When /^I query API for the classification with the UUID$/ do
  @response = {}
  ['xml', 'json'].each do |format|
    visit("/classification/#{@uuid}?format=#{format}")
    @response[format.to_sym] = body
  end
end

Given /^classification is imported to Solr$/ do
  si = Gnaclr::SolrIngest.new(@classification)
  si.ingest
end

When /^I search for "([^"]*)"$/ do |search_term|
  @response = {}
  search_term = URI.escape(search_term)
  ['xml', 'json'].each do |format|
    visit("/search?search_term=#{search_term}&format=#{format}")
    @response[format.to_sym] = body
  end
end

Then /^I get classification and path to this name in "([^"]*)" as "([^"]*)"$/ do |search_type, name_type|
  res = JSON.parse(@response[:json], :symbolize_names => true)[search_type.to_sym]
  res[:classifications].size.should > 0
  res[:classifications][0][:path].to_s.should_not == ""
  res[:classifications][0][:found_as].should == name_type
end

When /^I access API for the list of classifications$/ do
  @response = {}
  ['xml', 'json'].each do |format|
    visit("/classifications?format=#{format}")
    @response[format.to_sym] = body
  end
end

Then /^results will have revision information$/ do
  res = JSON.parse(@response[:json], :symbolize_names => true)
  res[:classifications][0][:revisions].should_not be_nil
end
