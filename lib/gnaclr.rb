module Gnaclr

  def self.uri_change_param(uri, param, value)
    return uri unless param
    par_val = "#{param}=#{URI.encode(value.to_s)}"
    uri_parsed = URI.parse(uri)
    return "#{uri}?#{par_val}" unless uri_parsed.query
    new_params = uri_parsed.query.split('&').reject { |q| q.split('=').first == param }
    uri = uri.split('?').first
    "#{uri}?#{new_params.join('&')}&#{par_val}"
  end

  def self.darwin_core_archive(file)
    begin
      m = DarwinCore.new(file).metadata
      return m.data ? { :title => m.title, :description => m.description, :authors => m.authors, :url => m.url } : {}
    rescue DarwinCore::Error
      return 
    end
  end

  def self.create_classification(uuid, data)
    classification = Classification.first(:uuid => uuid) || Classification.new(:uuid => uuid)
    classification.attributes = { :uuid => uuid, 
                                  :commit_hash => data[:commit_hash],
                                  :citation => data[:citation], 
                                  :file_name => data[:file_name], 
                                  :title => data[:title], 
                                  :description => data[:description], 
                                  :url => data[:url]}
    classification.save
    classification.author_classifications.each {|ac| ac.destroy!} 
    authors = []
    data[:authors].each do |a|
      author = Author.first(a) || Author.new(a)
      author.save
      authors << author
    end if data[:authors]
    authors.each { |a| ar = AuthorClassification.new(:author => a, :classification => classification); ar.save }
    classification.author_classifications.reload
    classification
  end
end
