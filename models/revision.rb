class Revision
  include DataMapper::Resource
  property :id,            Serial
  property :revision_hash, String, :required => true, :unique_index => true
  property :file_name,     String, :length => 256
  property :title,         String, :length => 256
  property :description,   Text
  property :url,           String, :length => 256
  property :created_at,    DateTime
  property :updated_at,    DateTime

  belongs_to :classification
  belongs_to :citation
  has n,     :authors, :through => :author_revision
end
