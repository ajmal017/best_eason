$(function(){
  
  // 找回密码前段验证
  $("#new_forget_password").validate({
    rules: {
      'user[email]': {
        required: true,
        remote: '/ajax/users/check_email_exists'
      }
    },
    messages: {
      'user[email]': {
        required: "邮箱不能为空",
        remote: '你输入的邮箱不存在'
      }
    }
  })

})
