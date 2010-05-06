class AuthorClassification
  include DataMapper::Resource
  property    :id,             Serial
  property    :primary_author, Integer
  property    :created_at,     DateTime
  property    :updated_at,     DateTime
  
  belongs_to  :author       
  belongs_to  :classification
end
