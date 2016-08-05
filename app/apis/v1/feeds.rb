module V1
  class Feeds < Grape::API
    resource :feeds, desc: "个人推荐相关" do

      add_desc "根据当前用户返回推荐信息列表(向上刷新, 初始化不需要传last_id)"
      params do
        optional :last_id, desc: "截止id", type: String
        requires :limit, desc: "每页数量", type: Integer, values: Array(1..50)
      end
      get :up do
        @feeds = MD::FeedHub.search(current_user.try(:id), sn_code)
        present (@feeds||[]).map(&:pretty_json).reverse
      end

      add_desc "根据当前用户返回推荐信息列表(向下翻页)"
      params do
        requires :start_id, desc: "开始id", type: String
        optional :end_id, desc: "截止id", type: String
      end
      get :down do
        @feeds = MD::Feed.app_feeds_down(current_user.try(:id), "uuid_#{sn_code}", params[:start_id])
          # if current_user.present?
          #   MD::Feed.search_feeds_for_down(current_user.try(:id), params[:start_id], params[:end_id], 10) || []
          # else
          #   []
          # end
        present @feeds.map(&:pretty_json)
      end

      add_desc "删除推荐信息（需要登录）"
      params do
        requires :id, desc: "feed_id", type: String
      end
      delete do
        raise VeriftyFail, "删除失败" unless ::MD::Feed.remove(current_user.try(:id)||sn_code, params[:id])
      end

    end
  end
end
