class Upload::Base < ActiveRecord::Base
  self.table_name = 'uploads'
  
  belongs_to :resource, polymorphic: true
end
