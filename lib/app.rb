# example model file
class App
  include DataMapper::Resource

  property :id,           Serial
  property :name,         String
  property :version,      String
  property :buildNumber,  String
  property :identifier,   String
end
