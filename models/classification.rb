class Classification
  include DataMapper::Resource
  property :id,           Serial
  property :uuid,         String, :unique_index => true, :required => true, :format => /([0-9a-f]){8}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){12}/
  property :file_name,    String, :length => 256
  property :title,        String, :length => 256
  property :description,  Text
  property :url,          String, :length => 256
  property :created_at,   DateTime
  property :updated_at,   DateTime
  property :citation,     Text

  has n, :authors, :through => :author_classification

end
