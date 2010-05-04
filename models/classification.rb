class Classification
  include DataMapper::Resource
  property :id,           Serial
  property :uuid,         String, :unique_index => true, :required => true, :format => /([0-9a-f]){8}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){12}/
  property :current_hash, String, :unique_index => true
  property :created_at,   DateTime
  property :updated_at,   DateTime

  has n, :revisions
  
  attr_writer :file, :data_path, :data

  def self.create(uuid, file)
    c = super(:uuid => uuid, :current_hash => nil)
    c.data_path = self.data_path(uuid)
    c.file = file
    c.data = c.add_data
    Revision.new(:classification => c, 
  end

  def self.delete_data_path(uuid)
    data_path = self.data_path(uuid)
    FileUtils.rm_rf(data_path) if File.exists?(data_path) 
  end

  private
  def self.data_path(uuid)
    File.join(SiteConfig.files_path, uuid)
  end

  def self.get_metadata(file_path)
    DarwinCore.new(file_path).metadata
  end
  
  def create_data_path
    unless File.exists?(@data_path)
      FileUtils.mkdir(@data_path) 
      Dir.chdir(@data_path)
      `git init`
    end
  end

  def add_data
    create_data_path
    Dir.chdir(@data_path)
    Dir.entries(Dir.pwd).each { |e| File.delete if File.file?(e) }
    data_file = open(File.join(@data_path, @file[:filename], 'w')
    data_file = @file.write(file[:tempfile].read(65536))
    data_file.close
    Dir.chdir(path)
    `git add .`
    `git add -u`
    `git commit -m "#{Time.now.strftime('%Y-%m-%d at %I:%M:%S %p')}"`
    Dir.chdir(SiteConfig.root_path)
  end

end
