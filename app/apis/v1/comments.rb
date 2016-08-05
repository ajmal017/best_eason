module V1
  class Comments < Grape::API
    resource :comments, desc: "评论相关" do

      add_desc "获取评论详情(不是一级评论则返回对应的一级评论)", entity: ::Entities::Comment
      get "/:comment_id" do
        comment = Comment.find(params[:comment_id])
        present comment.root_replyed_or_self, with: Entities::Comment
      end

      add_desc "获取评论", entity: ::Entities::Comment
      params do
        optional :all, using: ::Entities::Paginate.documentation
        requires :type, desc: "类型(#{::Commentable::COMMENTED_KLASS_ALL.map(&:to_s).join(',')})", type: String, values: ::Commentable::COMMENTED_KLASS_ALL.map(&:to_s)
        requires :id, desc: "类型对象id", type: String
        optional :last_id, desc: "起始查询评论id", type: Integer
      end
      get do
        commentable = StaticContent.get(params[:type].constantize.find(params[:id]))
        comments = commentable.undeleted_comments
        comments = comments.id_lt(params[:last_id]) if params[:last_id].present?
        present paginate(comments), with: Entities::Comment
      end

      add_desc "创建评论"
      params do
        requires :type, desc: "类型(#{::Commentable::COMMENTED_KLASS_ALL.map(&:to_s).join(',')})", type: String, values: ::Commentable::COMMENTED_KLASS_ALL.map(&:to_s)
        requires :id, desc: "类型对象id", type: String
        requires :content, desc: "评论内容", type: String
      end
      post do
        authenticate!
        commentable = params[:type].constantize.find(params[:id])
        comment = Comment.make(current_user.id, params[:content], commentable)
        raise ::APIErrors::VeriftyFail, comment.errors.messages.values.join(",") if comment.errors.present?
        present comment, with: Entities::Comment
      end

      add_desc "赞同"
      post ":comment_id/like" do
        authenticate!
        comment = Comment.find(params[:comment_id])
        raise ::APIErrors::VeriftyFail, "您已赞过该条评论" if comment.liked_by_user?(current_user.id)
        present Like.add(current_user.id, comment)
      end

      add_desc "删除评论"
      delete ":comment_id" do
        authenticate!
        comment = Comment.find(params[:comment_id])
        raise ::APIErrors::VeriftyFail, "你没有删除权限" if comment.commenter.id != current_user.id
        comment.destroy
        present comment, with: Entities::Comment
      end


    end

  end
end
