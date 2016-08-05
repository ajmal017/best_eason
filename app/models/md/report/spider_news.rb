class MD::Report::SpiderNews

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :date, type: Date
  field :num, type: Integer

  index "name" => 1
  index "date" => 1

end