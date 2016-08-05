$(function(){

  // 注册第一个页面-表单验证
  $("#j_registration_first").validate({
    rules: {
      'user[invite_code]': {
        remote: '/ajax/users/check_invite_code'
      },
      'user[email]': {
        required: true,
        format: /^([^@\s]+)@((?:[a-z0-9-]+\.)+[a-z]{2,})$/i,
        remote: '/ajax/users/check_email'
      },
      'user[captcha]': {
        required: true,
        remote: '/ajax/users/check_captcha'
      },
      'isAgree': {
        required: true
      }
    },
    messages: {
      'user[invite_code]': {
        remote: "优惠码不正确"
      },
      'user[email]': {
        required: "电子邮箱不能为空",
        format: "电子邮箱格式不正确",
        remote: "该账号已存在，<em>请</em><a href='/login'>直接登录</a>"
      },
      'user[captcha]': {
        required: "请输入验证码",
        remote: "验证码错误，请重新输入"
      },
      'isAgree': {
        required: '请同意财说用户协议',
      }
    }
  })

  $("#j_registration_phone").validate({
    rules: {
      'user[mobile]': {
        required: true,
        format: /^1\d{10}$/,
        remote: '/ajax/users/check_mobile_exists'
      },
      'user[username]': {
        required: true,
        min: 2,
        max: 30,
        format: /[^0-9]/,
        character: /[^_a-zA-Z0-9\u4E00-\u9FA5]/,
        remote: '/ajax/users/check_username'
      },
      'user[password]': {
        required: true,
        minlength: 6,
        maxlength: 20,
        format: /^[~!@#\$%\^&\*\(\)_\+=\-`,\.\/;’\[\]\\\|}{“:?><a-zA-Z0-9]{6,20}$/
      },
      'user[captcha]': {
        required: true,
        minlength: 4,
        maxlength: 4
      },
      'isAgree': {
        required: true
      }
    },
    messages: {
      'user[mobile]': {
        required: "请输入手机号",
        format: "请输入正确的手机号",
        remote: "手机号已被使用"
      },
      'user[password]': {
        required: "请输入密码",
        minlength: "密码控制在6~20位",
        maxlength: "密码控制在6~20位",
        format: "密码不能包含特殊字符"
      },
      'user[username]': {
        required: "请输入昵称",
        min: '昵称长度限制2~30位字符',
        max: '昵称长度限制2~30位字符',
        format: '昵称不能为纯数字',
        character: '昵称只支持中英文、下划线、数字',
        remote: "昵称已被使用"
      },
      'user[captcha]': {
        required: "请输入验证码",
        minlength: "验证码只能为4位",
        maxlength: "验证码只能为4位"
      },
      'isAgree': {
        required: '请同意财说用户协议',
      }
    }
  })

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

// 注册第一个页面-刷新验证码
function refresh_captcha(){
  var current_date = new Date();
  var captcha_url = "/captcha?i=" + current_date.getTime().toString();
  $("#img_captcha").attr("src", captcha_url);
}



