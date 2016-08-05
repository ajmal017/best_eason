#enconding=utf-8
module LoginMacros
  def admin_sign_in(user)
    visit nimda_path
    fill_in '邮箱地址', with: user.email
    fill_in '密码', with: user.password
    click_button '登陆'
  end
  
  def user_sign_in(user)
  end
end

RSpec.configure do |config|
  config.include LoginMacros
end