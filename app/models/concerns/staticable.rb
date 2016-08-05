module Staticable
  extend ActiveSupport::Concern

  def staticable
    StaticContent.find_by(sourceable_type: self.class.name, sourceable_id: self.id.to_s)
  end
end
