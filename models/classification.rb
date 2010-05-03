class Classification
  include DataMapper::Resource
  property :id,           Serial
  property :uuid,         String, :unique_index => true, :required => true, :format => /([0-9a-f]){8}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){12}/
  property :current_hash, String, :unique_index => true
  property :created_at,   DateTime
  property :updated_at,   DateTime

  has n, :revisions
  
  def new(uuid, file)
    super({:uuid => uuid, :current_hash => nil})
  end

  def self.delete_data_path(uuid)
    data_path = self.data_path(uuid)
    FileUtils.rm_rf(data_path) if File.exists?(data_path) 
  end

  private 
  def self.data_path(uuid)
    File.join(SiteConfig.files_path, uuid)
  end

end
