class Author
  include DataMapper::Resource
  property :id,         Serial
  property :given_name, String,  :unique_index => :idx1, :required => true
  property :surname,    String,  :unique_index => :idx1, :required => true
  property :email,      String,  :unique_index => :idx1, :required => false, :format => :email_address
  property :created_at, DateTime
  property :updated_at, DateTime
  
  has n, :revisions, :through => :author_revision
end
