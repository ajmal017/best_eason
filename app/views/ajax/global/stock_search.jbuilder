json.q @keyword
json.stocks @stocks do |stock|
  json.id stock[:stock_id]
  json.text localize(highlight("#{stock[:company_name]}(#{stock[:symbol]})", @keyword, highlighter: '<em>\1</em>'))
end