def get_repo(classification_id)
  classification = Classification.first(:id => classification_id)
  Grit::Repo.new(File.join(SiteConfig.files_path, classification.uuid))
end

def search_for(search_term, page, per_page)
  return [[],0] if search_term.strip == ''
  offset = (page - 1) * per_page
  original_search_term = search_term
  search_term = '[[:<:]]' + search_term
  d = repository(:default).adapter
  res = []
  total_rows = 0
  Classification.transaction do
    res = d.select("select SQL_CALC_FOUND_ROWS distinct c.*, '' as authors from classifications c left join author_classifications ac on c.id = ac.classification_id left join authors a on a.id = ac.author_id  where c.uuid = ? or c.title rlike ? or a.first_name rlike ? or a.last_name rlike ? limit ?, ?", original_search_term.strip, search_term, search_term, search_term, offset, per_page )
    total_rows = d.select("select FOUND_ROWS() as count")[0]
  end
  res.each do |c|
    authors = repository(:default).adapter.select("select a.first_name, a.last_name, email from authors a join author_classifications ac on ac.author_id = a.id where ac.classification_id = ?", c.id)
    c.authors = authors
  end
  [res, total_rows]
end

def prepare_data(classifications, total_rows, page, per_page, search_term = nil, show_revisions = false)
  total_pages = total_rows/per_page + (total_rows % per_page == 0 ? 0 : 1)
  previous_page = page > 1 ? uri_change_param(url, 'page', page - 1) : nil
  next_page = page < total_pages ? uri_change_param(url, 'page', page + 1) : nil
  cl = []
  classifications.each do |c|
    cl << prepare_classification(c, show_revisions)
  end
  res = { 
    :url => base_url, :page => page, :per_page => per_page, :total_count => total_rows, 
    :total_pages => total_pages, :previous_page => previous_page, :next_page => next_page,
    :classifications => cl
  }
  res.merge!({:search_term => search_term}) if :search_term.to_s != ''
  res
end

def prepare_classification(classification, show_revisions)
  c = classification
  authors = c.authors.sort_by {|a| a.last_name.downcase}.map { |a| {:first_name => a.first_name, :last_name => a.last_name, :email => a.email} }
  file_url = "#{base_url}/files/#{c.uuid}/#{c.file_name}"
  res = { 
    :id => c.id, :uuid => c.uuid, :file_url => file_url, 
    :title => c.title, :description => c.description, 
    :url => c.url, :citation => c.citation, :authors => authors, 
    :created => c.created_at, :updated => c.updated_at
  }
  if show_revisions 
    repository = get_repo(classification.id)
    commits = repository.commits.map { |c| { :message => c.message, :tree_id => c.tree.id, :file_name => c.tree.blobs.first.name, :url => "#{base_url}/classification_file/#{classification.id}/#{c.tree.id}" }}
    res.merge!({:revisions => commits})
  end
  res
end

def uri_change_param(uri, param, value)
  return uri unless param
  par_val = "#{param}=#{URI.encode(value.to_s)}"
  uri_parsed = URI.parse(uri)
  return "#{uri}?#{par_val}" unless uri_parsed.query
  new_params = uri_parsed.query.split('&').reject { |q| q.split('=').first == param }
  uri = uri.split('?').first
  "#{uri}?#{new_params.join('&')}&#{par_val}"
end

def darwin_core_archive(file)
  begin
    m = DarwinCore.new(file).metadata
    return m.data ? { :title => m.title, :description => m.description, :authors => m.authors, :url => m.url } : {}
  rescue DarwinCore::Error
    return 
  end
end

def create_classification(uuid, data)
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

get '/main.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :main
end

