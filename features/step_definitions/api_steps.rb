Given /^classification UUID as "([^"]*)"$/ do |uuid|
  @uuid = uuid
end

Given /^there is no classification with the UUID$/ do
  Classification.first(:uuid => @uuis).should be_nil
end

Given /^there is a "([^"]*)" local file$/ do |file_name|
  @file = File.join(SiteConfig.root_path, 'spec', 'files',  file_name)
  File.exist?(@file).should be_true
end

When /^I upload the file through the api$/ do
  @classification_count = Classification.count
  post('/classifications', :file => Rack::Test::UploadedFile.new(@file, 'applicaation/gzip'), :uuid => @uuid)
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

Given /^there is a classification with the UUID$/ do
  Given %{there is a "data_v1.tar.gz" local file}
  And %{I upload the file through the api}
  cl = Classification.first(:uuid => @uuid)
  cl.class.should == Classification
  @title = cl.title
end

Then /^classification will be updated$/ do
  Classification.first(:uuid => @uuid).title.should_not == @title
end

Then /^old revision will still be accessible$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^the file should be rejected$/ do
  Classification.count.should == @classification_count
end
