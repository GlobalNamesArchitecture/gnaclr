class AuthorRevision
  include DataMapper::Resource
  property    :id,             Serial
  property    :primary_author, Integer,   :unique_index => :idx1
  property    :created_at,     DateTime
  property    :updated_at,     DateTime
  
  belongs_to  :author,                    :unique_index => :idx1       
  belongs_to  :revision,                  :unique_index => :idx1
end
