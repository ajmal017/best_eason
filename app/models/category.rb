class Category < ActiveRecord::Base
  ARTICLE = {
    "Stocks" => "公司个股",
    "Hot" => "热门组合",
    "School" => "财说学堂",
    "Financial report" => "财报解读",
    "Others" => "其它"
  }
  
  ARTICLES = {
    "" => "全部",
    "Stocks" => "公司个股",
    "Hot" => "热门组合",
    "School" => "财说学堂",
    "Financial report" => "财报解读",
    "Others" => "其它"
  }
  
  has_many :category_articles
  has_many :articles, through: :category_articles
end
