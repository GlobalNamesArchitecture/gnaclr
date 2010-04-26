class Classification
  include DataMapper::Resource
  property :id,          Serial
  property :uuid,        String, :unique_index => true
  property :name,        String
  property :description, String
  property :file_name,   String
  property :file_type,   String
  property :url,         String
  property :created_at,  DateTime
  property :updated_at,  DateTime
  
  belongs_to :agent
  has n, :authors, :through => Resource

  validates_present :name
  validates_present :file_name
  validates_present :file_type
end
