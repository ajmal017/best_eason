module Entities
  class Notification < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "通知id"}
    expose :type, documentation: {type: String, desc: "类型"} do |data, option|
      data.type.gsub("Notification::", "")
    end
    expose :read, documentation: {type: Grape::API::Boolean, desc: "是否已读"}
    expose :created_at, documentation: {type: String, desc: "创建时间"}, format_with: :to_i
    expose :title, documentation: {type: String, desc: "标题"}
    expose :content, documentation: {type: String, desc: "内容"}
    expose :origin_mentionable_id, as: :mentionable_id, documentation: {type: Integer, desc: "上层对象id"}
    expose :origin_mentionable_type, as: :mentionable_type, documentation: {type: String, desc: "上层对象类型"}
    expose :mentionable_info, documentation: {type: Hash, desc: "上层对象信息"} do |data, options|
      data.try(:mentionable).try(:source_info)
    end
    expose :triggered_user, using: "::Entities::BaseUser", documentation: {type: Hash, desc: "目标用户"}
    expose :origin_targetable_id, as: :targetable_id, documentation: {type: Hash, desc: "根对象id"}
    expose :origin_targetable_type, as: :targetable_type, documentation: {type: Hash, desc: "根对象类型"}
    expose :targetable_info, documentation: {type: Hash, desc: "根对象信息"} do |data, options|
      data.try(:targetable).try(:source_info)
    end
    expose :origin_originable_id, as: :originable_id, documentation: {type: Hash, desc: "源对象id"}
    expose :origin_originable_type, as: :originable_type, documentation: {type: Hash, desc: "源对象类型"}
    expose :originable_info, documentation: {type: Hash, desc: "源对象信息"} do |data, options|
      originable = data.try(:originable)
      (originable.is_a? ::Comment) ? originable.text : nil
    end
  end

end
