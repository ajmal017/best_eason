假如(/^输入不存在绑定用户且格式正确的手机号$/) do
  @mobile = 13500000000
end

当(/^调用验证手机号可用性接口时$/) do
  @response = get "/api/v1/users/verify_mobile", mobile: @mobile
end

那么(/^得到该手机号可以使用$/) do
  success!
end

假如(/^输入存在绑定用户且格式正确的手机号$/) do
  @mobile = 13500000000
  FactoryGirl.create(:user, mobile: @mobile)
end

那么(/^得到该手机号已使用$/) do
  success!
  error_code.should == 1001
  error_msg.should == "手机号已使用!"
end

假如(/^输入格式不正确的手机号$/) do
  @mobile = 134515151
end

那么(/^得到该手机号格式不正确$/) do
  failed!
  error_code.should == 2001
end
