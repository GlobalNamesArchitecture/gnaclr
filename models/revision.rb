class Revision
  include DataMapper::Resource
  property :id,           Serial
  property :hash,         String, :required => true, :unique_index => true
  property :file_name,    String
  property :title,        String
  property :description,  Text
  property :url,          String
  property :created_at,   DateTime
  property :updated_at,   DateTime

  belongs_to :classification
  belongs_to :citation
  has n,     :authors, :through => :author_revision
end
