class MD::Data::Stock
  include Mongoid::Document

  field :_id, type: Integer
  field :symbol
  field :cname
end
