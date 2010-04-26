class Author
  include DataMapper::Resource
  property :id,         Serial
  property :given_name, String,  :unique_index => :idx1
  property :surname,    String,  :unique_index => :idx1
  property :email,      String,  :unique_index => :idx1
  property :created_at, DateTime
  property :updated_at, DateTime
  
  has n, :classifications, :through => Resource
end
