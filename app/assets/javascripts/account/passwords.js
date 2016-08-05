// 找回密码页面-刷新验证码
function refresh_captcha(){
  var current_date = new Date();
  var captcha_url = "/captcha?i=" + current_date.getTime().toString();
  $("#img_captcha").attr("src", captcha_url);
}

$(function(){

  $("#new_account_passwords input").focus(function(){
    $(this).parents('dd').find('.errorTip').hide();
  });

  $("#new_account_passwords").validate({
    rules: {
      'user[email]': {
        light_required: true,
        password_remote: true
      },
      'user[captcha]': {
        required: true,
        remote: '/ajax/users/check_captcha'
      }
    },
    messages: {
      'user[email]': {
        light_required: '请输入电子邮箱',
        password_remote: '该邮箱未注册'
      },
      'user[captcha]': {
        required: "请输入验证码",
        remote: "验证码错误，请重新输入"
      }
    },
    success: function(label,element){
      if($.inArray($(element).attr('id'), ['user_username', 'user_email']) != -1){
        $('#user_username, #user_email').parents('dd').find('.errorTip').remove();
      }else{
        $(element).parents('dd').find('.errorTip').remove();
      }
    },
    submitHandler: function(form){
      $(form).find('[type=submit]').attr('disabled', 'disabled');
      form.submit();
    }
  })

  $("#new_account_passwords_phone").validate({
    rules: {
      'user[mobile]': {
        required: true,
        format: /^1\d{10}$/,
        remote: '/ajax/users/check_mobile_register'
      },
      'user[captcha]': {
        required: true
      }
    },
    messages: {
      'user[mobile]': {
        required: '请输入手机号',
        format: '请输入正确的手机号',
        remote: '该手机号未注册'
      },
      'user[captcha]': {
        required: "请输入验证码"
      }
    }
  });

  // 重置密码-表单验证
  $('#reset_password_form').validate({
    rules: {
      'user[password]': {
        required: true,
        minlength: 6,
        maxlength: 16,
        format: /^[~!@#\$%\^&\*\(\)_\+=\-`,\.\/;’\[\]\\\|}{“:?><a-zA-Z0-9]{6,20}$/
      },
      'user[password_confirmation]': {
        required: true,
        minlength: 6,
        maxlength: 16,
        format: /^[~!@#\$%\^&\*\(\)_\+=\-`,\.\/;’\[\]\\\|}{“:?><a-zA-Z0-9]{6,20}$/,
        equalTo: '#user_password'
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
      }
    }
  });

  $(".tab_ul").tabso({
    cntSelect:".R_dls",
    tabEvent:"click",
    onStyle : "active",
    menuChildSel : "li"
  });

  // 发送验证码，倒计时60s
  var timer;
  $("#bindPhone").click(function(){
    if( !timer && $("#user_mobile").valid() ){
      $.ajax({
        url: "/ajax/users/send_sms_code", 
        data: { 'mobile': $('#user_mobile').val() }, 
        type: "PUT",
        success: function(data){
          if (data.status) {
            var seconds=60, that=$("#bindPhone");
            $(that).text('重新发送('+ seconds +')')
            timer = window.setInterval(function(){
              if (seconds>1){
                $(that).text('重新发送('+ --seconds +')')
              }else{
                $(that).text('发送验证码');
                window.clearInterval(timer);
                timer = null;
              }
            },1000);
          } else {
            CaishuoAlert(data.msg)
          }
        }
      });
    }
  });

})
