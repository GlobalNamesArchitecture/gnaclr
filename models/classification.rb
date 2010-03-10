class Classification
  include DataMapper::Resource
  property :id,         Serial
  property :uuid,       String, :unique_index => true
  property :name,       String
  property :created_at, DateTime
  property :updated_at, DateTime
  
  belongs_to :agent

  validates_present :name
end
