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
    @tmp_path = File.join(@repo_path, "dwca_tmp_dir")
    @dwca_tmp_path = File.join(@tmp_path, @file[:filename])
    @repo = nil
    @data = nil
  end

  def process_file
    @data = obtain_metadata
    add_revision if @data
    @data
  end

  private


  def create_repo_path
    unless File.exists?(@repo_path)
      FileUtils.mkdir(@repo_path) 
      Dir.chdir(@repo_path)
      `git init`
    end
    @repo = Grit::Repo.new(@repo_path)
    
    FileUtils.rm_rf(@tmp_path) if File.exist? @tmp_path
    FileUtils.mkdir(@tmp_path)
    data_file = open(@dwca_tmp_path, 'w')
    data_file.write(@file[:tempfile].read)
    data_file.close
    Dir.chdir(@root_path)
  end

  def obtain_metadata
    create_repo_path
    begin
      dc = DarwinCore.new(@dwca_tmp_path)
      metadata = dc.metadata
      @data = metadata ? {:title => metadata.title, :description => metadata.abstract, :url => metadata.url, :citation => metadata.citation, :authors => metadata.authors, :file_name => @file[:filename]} : nil
      dc.archive.clean
      Dir.entries(@repo_path).each { |e| File.delete(File.join(@repo_path, e)) if File.file?(File.join(@repo_path, e)) }
      FileUtils.mv(@dwca_tmp_path, @repo_path)
    rescue DarwinCore::Error => e
      DWCA.delete_repo_path(@repo_path) if @repo.commits.empty? 
      # raise e
      @data = nil
    ensure 
      FileUtils.rm_rf(@tmp_path) if File.exists? @repo_path
    end
    @data
  end

  def add_revision
    Dir.chdir(@repo_path)
    `git add .`
    `git add -u`
    `git commit -m "#{Time.now.strftime('%Y-%m-%d at %I:%M:%S %p')}"`
    Dir.chdir(@root_path)
  end

end
