class Classification
  include DataMapper::Resource
  property :id,           Serial
  property :uuid,         String, :unique_index => true, :required => true, :format => /([0-9a-f]){8}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){12}/
  property :current_hash, String, :unique_index => true
  property :created_at,   DateTime
  property :updated_at,   DateTime

  has n, :revisions
  
  def initialize 
    super
  end

end
