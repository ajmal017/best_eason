module Entities
  class Comment < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "id"}
    expose :content, documentation: {type: String, desc: "内容"} do |data, options|
      data.final_mobile_content || ""
    end
    expose :likes_count, format_with: :to_f, documentation: {type: Integer, desc: "赞同数"}
    expose :is_liked, documentation: {type: Grape::API::Boolean, desc: "当前用户是否赞同"} do |data, options|
      data.liked_by_user?(options[:current_user].id) rescue false
    end
    expose :is_chat?, as: :is_chat, documentation: {type: Grape::API::Boolean, desc: "是否可以查看对话"}
    expose :deleted, documentation: {type: Grape::API::Boolean, desc: "是否已删除"}
    expose :comments_count, format_with: :to_f, documentation: {type: Integer, desc: "评论数"}
    expose :source_info, documentation: {type: Integer, desc: "评论源头"} do |data, options|
      result = {id: data.origin_top_commentable_id, type: data.origin_top_commentable_type, title: data.top_commentable.try(:source_info)}
      result.merge({market: data.top_commentable.try(:market_area_name)}) if data.origin_top_commentable_type == "BaseStock"
      result
    end
    expose :created_at, documentation: {type: String, desc: "创建时间"}
    expose :commenter, using: "::Entities::BaseUser", documentation: {type: Hash, desc: "评论人"}
    expose :is_top, documentation: {type: Grape::API::Boolean, desc: "是否为一级评论"} do |data, options|
      data.root_replyed_id.nil?
    end
    expose :top_comment, documentation: {type: Hash, desc: "顶层评论信息"} do |data, options|
      data.root_replyed_id.present? ? {id: data.root_replyed.id, deleted: data.root_replyed.deleted, content: data.root_replyed.final_mobile_content, commenter: {id: data.root_replyed.commenter.id, username: data.root_replyed.commenter.username}} : {}
    end
  end
end
