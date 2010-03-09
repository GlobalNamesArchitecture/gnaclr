# example model file
class Key
  include DataMapper::Resource
  property :id,         Serial
  property :domain,     String
  property :salt,       String
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_present :domain
  validates_present :salt
  
  def self.key_by_domain(domain)
    k = first(:domain => domain)
    k ? Digest::SHA1.hexdigest(k.domain + k.salt.to_s) : nil
  end

  def key
    Digest::SHA1.hexdigest(domain + salt.to_s)
  end

  def self.gen_salt
    UUID.create_v4.to_i
  end
end
