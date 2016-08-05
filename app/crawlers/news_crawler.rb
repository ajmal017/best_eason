# 返回页面title
class NewsCrawler
  include Crawlable

  def process_page_results(page)
    page.title
  end
end