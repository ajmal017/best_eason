假如(/^登录当前用户$/) do
  @old_password = "12345678"
  create_current_user! password: @old_password, password_confirmation: @old_password
end

假如(/^输入不正确的原密码$/) do
  @old_password = "11111212141"
end

当(/^调用修改用户密码的接口时$/) do

  header "Authorization", current_user.api_tokens.first.access_token
  header "X-SN-Code", current_user.api_tokens.first.sn_code

  @response = put "/api/v1/users/password", {old_password: @old_password, new_password: @new_password, new_password_confirmation: @new_password_confirmation}
end

那么(/^得到原密码不正确$/) do
  failed!
  error_msg.should == "原密码不正确!"
end

假如(/^输入正确的原密码并且输入的新密码与重复新密码不一致$/) do
  @old_password = "12345678"
  @new_password = "11111111"
  @new_password_confirmation = "11111112"
end

那么(/^得到新密码与重复新密码不一致$/) do
  failed!
  error_msg.should == "两次输入的密码不一致!"
end

假如(/^输入正确的原密码，新密码和重复新密码$/) do
  @old_password = "12345678"
  @new_password = "11111111"
  @new_password_confirmation = "11111111"
end

那么(/^得到密码修改成功$/) do
  success!
  current_user.reload.password.should == @new_password
end
