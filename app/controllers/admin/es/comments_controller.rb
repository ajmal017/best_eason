module Admin::ES
  class CommentsController < Admin::ApplicationController

    def index
      if params[:q].present?
        query = {query: { match: { content: params[:q] } }, :highlight=>{:fields=>{:content=>{}}}}
      else
        query = {query: { match_all: {} }, sort: {created_at: {order: "desc"}}}
      end
      @page_title = "评论"
      @comments = ::ES::Comment.search(query).paginate(page: params[:page]).per_page(20)
    end


    def show
      @page_title = "查看评论详情"
      @comment = ::ES::Comment.find(params[:id])
    end

    def destroy
      Comment.find(params[:id]).destroy
    end
  end
end
