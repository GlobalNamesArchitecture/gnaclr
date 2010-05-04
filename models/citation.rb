class Citation
  include DataMapper::Resource
  property :id,   Serial
  property :citation, String, :length => 256, :unique_index => true
  property :created_at,  DateTime
  property :updated_at,  DateTime

  has n, :revisions
end
