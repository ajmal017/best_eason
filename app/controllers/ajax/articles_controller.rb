class Ajax::ArticlesController < Ajax::ApplicationController
  before_action :load_article

  def comments
    @comments = @article.comments.order("created_at desc").paginate(:page => params[:page]||1, :per_page => Comment::PER_PAGE)
  end

  private
  def load_article
  	@article = Article.find(params[:id])
  end

end
