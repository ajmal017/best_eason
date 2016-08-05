module Entities
  class Topic < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "id"}
    expose :title, as: :tag, documentation: {type: String, desc: "标签"}
    expose :sub_title, as: :title, documentation: {type: String, desc: "标题"}
    expose :modified_at, documentation: {type: String, desc: "时间"}
  end
end
