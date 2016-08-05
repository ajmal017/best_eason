# 接口logger
$faraday_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'faraday.log'))

# 历史数据 logger
$finance_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'finance.log'))

# Xignite logger
$xignite_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'xignite.log'))

# 重试历史数据 logger
$finance_retry_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'finance_retry.log'))

# 监控历史数据 logger
$monitor_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'monitor_finance.log'))

# BaseStock logger
$base_stock_logger = ActiveSupport::Logger.new(Rails.root.join('log', 'base_stock.log'))

# crawler logger
$crawler_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'crawler.log'))

$monitor_crawler_logger = ActiveSupport::Logger.new(Rails.root.join('log', 'crawler_monitor.log'))

# 实时数据 logger
$rt_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'rt_quote.log'))

# 实时临时日志
$rt_intraday = ActiveSupport::Logger.new(Rails.root.join('log', 'rt_intraday.log'))

# Corp active logger
$corp_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'corp_active.log'))

# basket index calculate logger
$basket_index_logger = ActiveSupport::Logger.new(Rails.root.join('log', 'basket_index_cal.log'))

# sneakers log
$pms_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'pms_logger.log'))
#
# $sneakers_discard_logger = ActiveSupport::Logger.new(Rails.root.join('log', 'sneakers_discard.log'))

# 计算用户资产 log
$investment_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'investment.log'))

$memory_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'memory.log'))

# importer logger
$importer_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'importer.log'))

# fundatmental logger
$fundatmental_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'fundatmental.log'))

# pms_deadletter logger
$pms_deadletter_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'pms_deadletter.log'))

# jpush logger
$jpush_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'jpush.log'))

# 大赛组合自动调仓 logger
$adjust_basket_by_order_loger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'adjust_basket_by_order.log'))

# 下单失败 logger
$order_fail_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'order_fail.log'))

$redis_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'redis.log'))

# api logger
$api_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'api.log'))

# 推荐文章推送失败 logger
$recommend_push_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'recommend_push.log'))

# rest logger
$rest_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'rest.log'))

# seo logger
$seo_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'seo.log'))

# screenshot logger
$screenshot_logger = ActiveSupport::PrettyLogger.new(Rails.root.join('log', 'screenshot.log'))
