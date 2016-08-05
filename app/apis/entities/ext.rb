module Entities
  class Paginate < ::Entities::Base
    expose :per_page, documentation: {type: Integer, desc: "每页数(1~50)", values: Array(1..50)}
    expose :page, documentation: {type: Integer, desc: "页数"}
  end

  class P2pPaginate < ::Entities::Base
    expose :last_id, documentation: {type: Integer, desc: "最后一个id"}
    expose :page_size, documentation: {type: Integer, desc: "每页数(1~50)", values: Array(1..50)}
  end

  class Error < ::Entities::Base
    expose :code
    expose :message
  end
end
