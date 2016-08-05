class ArticleCrawler
  IGNORE_IMAGES =[    "http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZYMXeesLiaYUNBsltS0UwmycbpeiaC2ria4eicJxGbFrH4w2pPKF6FiagLYFO8qMJfdF7AVe2sB4CQdfjw/0",    "http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9Zbnzh7ZAq141azxZYIZVUHqMyuibVwS3Wv04m3X20ib80Rks3qLkCXuyf0aBoy9RicnibkuEUe460Hkxg/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZbicAyVM3h6HX77OXO5ZhRAs1jbic2OAkm9JhZI1JJiaQu5cxByTIvuDrbdVnZG4hRBOy1SV22MLDrOg/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZbZicH8uczj5ZKQ9zlLwbRuowfL59Bd2DcuLEziaOd3WxTWicsnmE8bnf1PbGyY4aWyTBc4BaFkk6qRg/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZYpib0BuV461nibMDDyjyhcGTWCEv26yheVTYpia8Ju29gwK0kPWpNICiba4zSt9tHK163acxRrfKeKGQ/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9Zb4DejqJJabDPMK4vDssGetOia84WEm2CKxb3NBnZetzthZo0bTz3PJ1iblt9oLx3EGEI7DegfzibtHA/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9Zb5C9SYG3T0W1uyGMqJoI44UYTibrdicSVibIszBuWXj2Y7NxC6BPvG3PyrWjpH8A8ribDp0Zf8KxFm3A/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZaL1hpeYUvnOSRWnPfqWoz9Wlp6UmaWNX4LTrJ8u6RBuzxyOB2W6qZbiabNp4F3JKYDzGFtI3G2l0Q/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZbWUrLjd6Cgk7AfaoicjY46ERxUuDOmJfkQ5NRYAbwchEjcWXYsb0PFUWY72iaROCrSvFUAt3ft3Iww/0",
"http://mmbiz.qpic.cn/mmbiz/1h7hJqjN9ZZlQUxfNQEuaj1TrlpwVEIQic3PkibufSgIAzEDh3MHdLEe7kPIkPDThagic3HQyZgPrVCTavk8XZoEg/0"
  ]
  
  IGNORE_TEXT = [
    "点击左下角",
    "回复",
    "分享财说好文",
    "给您一张财富绿卡"
  ]
  
  include Crawlable
  
  def process_page_results(page)
    if article = Article.fuzzy_search(url: @website, title: title(page))
      page_content, images = upload_images(page)
      $crawler_logger.info("页面内容: #{page_content}")
      article.update_attrs(post_date: post_date(page).to_date, post_user: post_user(page), content: page_content, url: @website, images: images, synchronized: true)
    end
  end
  
  def title(page)
    page.search("div[@class='rich_media_inner']/h2").text.strip
  end
  
  def post_date(page)
    page.search("div[@class='rich_media_meta_list']/em").text.strip
  end
  
  def post_user(page)
    page.search("div[@class='rich_media_meta_list']/a").text.strip
  end
  
  def p_elements(page)
    page.search("div[@class='rich_media_content']").first.elements
  end
  
  def upload_images(page)
    page_content = ""
    images = []
    p_elements(page).each do |e|
      next if IGNORE_TEXT.any? { |x| e.text.include?(x) }
      e.search("img").each do |i|
        ua = Upload::Article.create(remote_image_url: i["src"] || i["data-src"])
        i["src"] = ua.image.url
        i["style"] = "width: " + i["data-w"] + "px;margin: 0 auto;" if i["data-w"].present?
        images << ua unless ua.errors.present?
      end
      page_content += e.to_html
    end
    [page_content, images]
  end
end
