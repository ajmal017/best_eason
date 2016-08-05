module AutoSeo
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
    after_commit :push_url, if: -> { Rails.env.production? }
  end

  def push_url
    Resque.enqueue(PushSeoWorker, seo_urls)
  end

  def seo_urls
    []
  end
end
