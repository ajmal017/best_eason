$(function(){
  
  // 注册第二个页面-表单获得焦点
  $("#j_registration_second input[name!='user[password]']").focus(function(){
    $('.prompt').hide();
    $(this).next('.prompt').show().next('.errorTip').hide();
  }).blur(function(){
    $('.prompt').hide();  
  })

  // 注册第二个页面-表单验证
  $('#j_registration_second').validate({
    rules: {
      'user[password]': {
        required: true,
        minlength: 6,
        maxlength: 20,
        format: /^[~!@#\$%\^&\*\(\)_\+=\-`,\.\/;’\[\]\\\|}{“:?><a-zA-Z0-9]{6,20}$/
      },
      'user[password_confirmation]': {
        required: true,
        minlength: 6,
        maxlength: 20,
        format: /^[~!@#\$%\^&\*\(\)_\+=\-`,\.\/;’\[\]\\\|}{“:?><a-zA-Z0-9]{6,20}$/,
        equalTo: '#user_password'
      },
      'user[username]': {
        required: true,
        min: 2,
        max: 30,
        format: /[^0-9]/,
        character: /[^_a-zA-Z0-9\u4E00-\u9FA5]/,
        remote: '/ajax/users/check_username'
      }
    }, 
    messages: {
      'user[password]': {
        required: "密码不能为空",
        minlength: "密码不能少于6位",
        maxlength: "密码不能大于20位",
        format: "密码不能包含空格或特殊字符"
      },
      'user[password_confirmation]': {
        required: "确认密码不能为空",
        minlength: "密码不能少于6位",
        maxlength: "密码不能大于20位",
        format: "密码不能包含空格或特殊字符",
        equalTo: "两次输入密码不一致"
      },
      'user[username]': {
        required: "昵称不能为空",
        min: "昵称最少2个字符",
        max: "昵称最多30个字符",
        format: "不能全为数字",
        character: "只能包含中英文、下划线和数字",
        remote: "此昵称已经有人使用"
      }
    }
  });

})

