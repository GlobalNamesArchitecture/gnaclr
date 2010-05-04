class UUIDFormatError < RuntimeError; end

class DWCA
  
  def self.delete_repo_path(path)
    FileUtils.rm_rf(path) if File.exists?(path) 
  end
  
  def initialize(uuid, file, path, root_path)
    @uuid = uuid
    @repos_path = path
    @root_path = root_path
    @file = file
    @repo_path = File.join(@repos_path, @uuid)
    @dwca_path = File.join(@repo_path, @file[:filename])
    @repo = nil
    @data = nil
  end

  def process_file
    raise DWCA::UUIDFormatError unless UUID.valid?(@uuid) 
    add_data
    @data = obtain_metadata
  end

  private


  def create_repo_path
    unless File.exists?(@repo_path)
      FileUtils.mkdir(@repo_path) 
      Dir.chdir(@repo_path)
      `git init`
    end
    @repo = Grit::Repo.new(@repo_path)
    Dir.chdir(@root_path)
  end

  def add_data
    create_repo_path
    Dir.chdir(@repo_path)
    Dir.entries(Dir.pwd).each { |e| File.delete if File.file?(e) }
    data_file = open(@dwca_path, 'w')
    data_file.write(@file[:tempfile].read(65536))
    data_file.close
    Dir.chdir(@repo_path)
    `git add .`
    `git add -u`
    `git commit -m "#{Time.now.strftime('%Y-%m-%d at %I:%M:%S %p')}"`
    Dir.chdir(@root_path)
  end

  def obtain_metadata
    begin
      metadata = DarwinCore.new(@dwca_path).metadata
      @data = {:title => metadata.title, :description => metadata.abstract, :url => metadata.url, :citation => metadata.citation, :authors => metadata.authors, :revision_hash => @repo.commits[0].id, :file_name => @file[:filename]}
    rescue DarwinCore::Error => e
      DWCA.delete_repo_path if @repo.commits.empty?
      raise e
    end
    @data
  end

end
