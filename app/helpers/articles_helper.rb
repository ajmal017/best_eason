module ArticlesHelper
  def category_target(article)
    category_articles_path(article.categories.first) if article.categories.present?
  end
  
  def category_target_text(article)
    article.categories.first.name  if article.categories.present?
  end
  
  def article_target(category, article)
    category.present? ? category_article_path(category, article) : article_path(article)
  end
  
  def toggle_viewable_path(article)
    if article.viewable
      link_to "隐藏", toggle_viewable_admin_article_path(article), remote: true
    else
      link_to "公开", toggle_viewable_admin_article_path(article), remote: true
    end
  end
end
