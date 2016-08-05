function showCropModal(){
  $("#j_crop_logo").fadeIn().show();
}

$(function(){
  $("#hongbao").validate({
    rules: {
      'user[invite_code]': {
        required: true,
        remote: '/ajax/users/check_invite_code'
      }
    },
    messages: {
      'user[invite_code]': {
        required: "优惠码不能为空",
        remote: "优惠码不正确"
      }
    }
  })

  // iframe 不刷新提交文件
  // $("#real_setting_avatar").change(function(){
//     var currentForm = $(this).parents("form");
//     if($("iframe[name='curform']").length > 0){
//       var thisIframe = $("iframe[name='curform']");
//     }else{
//       var thisIframe = $("<iframe style='opacity:0;_filter:alpha(opacity=0)'></iframe>").attr("name",currentForm.attr("target"));
//     }
//     $(currentForm).after(thisIframe);
//     $(currentForm).submit();
//
//     showCropModal();
//     $("#j_crop_logo").find(".upload-head").html("<center>头像文件上传中...</center>");
//});
  
  $("#real_setting_avatar").change(function(){
    var currentForm = $(this).parents("form");
    $(currentForm).submit();
    
  });

  $("#j_crop_cancel").on('click', function(){
    $("#j_crop_logo").fadeOut().hide();
    $("iframe").remove();
    return false;
  })

  // 个人设置-修改密码
  $("#update_password_form input:not(:checkbox)").focus(function(){
    $('.prompt').hide();
    $(this).next('.prompt').show().next('.errorTip').hide();
  }).blur(function(){
    $('.prompt').hide();
  })

  // 账号设置-修改密码-表单验证
  $('#update_password_form').validate({
    rules: {
      'user[current_password]': {
        required: true,
        remote: '/ajax/users/check_password'
      },
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
      }
    }, 
    messages: {
      'user[current_password]': {
        required: "当前密码不能为空",
        remote: "当前密码不正确"
      },
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

  // 个人设置-修改密码
  $("#reset_password_form input:not(:checkbox)").focus(function(){
    $('.prompt').hide();
    $(this).next('.prompt').show().next('.errorTip').hide();
  }).blur(function(){
    $('.prompt').hide();
  })
  
  
  // 账号设置-个人资料
  $("#j_profile_basic input:not(:checkbox)").focus(function(){
    $('.prompt').hide();
    $(this).next('.prompt').show().next('.errorTip').hide();
  }).blur(function(){
    $('.prompt').hide();
  })
  
  
  // 账号设置-个人资料-表单验证
  $('#j_profile_basic').validate({
    rules: {
      'user[username]': {
        min: 2,
        max: 30,
        format: /[^0-9]/,
        character: /[^_a-zA-Z0-9\u4E00-\u9FA5]/,
        remote: '/ajax/users/check_username'
      },
      'user[headline]': {
        min: 4,
        max: 30
      },
      'user[profile_attributes][intro]': {
        max: 140
      }
    }, 
    messages: {
      'user[username]': {
        min: '不能小于2位',
        max: '不能大于30位',
        format: '不能全为数字',
        character: '只能包含中英文、下划线和数字',
        remote: "此昵称已经有人使用"
      },
      'user[headline]': {
        min: '不能小于4位',
        max: '不能大于30位'
      },
      'user[profile_attributes][intro]': {
        max: '140字以内'
      }
    }
  });

  // 账号设置-绑定手机号
  $('#bind_mobile_form').validate({
    rules: {
      'user[mobile]': {
        required: true,
        format: /^1\d{10}$/,
        remote: function(){
          return {
            type: "GET",
            async: false,
            url: '/ajax/users/check_mobile_exists'
          }
        }
      },
      'user[code]': {
        required: true,
        minlength: 4,
        maxlength: 4
      }
    },
    messages: {
      'user[mobile]': {
        required: "手机号不能为空",
        format: "手机号格式不正确",
        remote: "手机号已被绑定"
      },
      'user[code]': {
        required: "验证码不能为空",
        minlength: "验证码只能为4位",
        maxlength: "验证码只能为4位"
      }
    }
  });

  $('#bind_mobile_and_password_form').validate({
    rules: {
      'user[mobile]': {
        required: true,
        format: /^1\d{10}$/,
        remote: function(){
          return {
            type: "GET",
            async: false,
            url: '/ajax/users/check_mobile_exists'
          }
        }
      },
      'user[code]': {
        required: true,
        minlength: 4,
        maxlength: 4
      },
      'user[password]': {
        required: true,
        minlength: 6,
        maxlength: 20,
        format: /^[~!@#\$%\^&\*\(\)_\+=\-`,\.\/;’\[\]\\\|}{“:?><a-zA-Z0-9]{6,20}$/
      },
    },
    messages: {
      'user[mobile]': {
        required: "手机号不能为空",
        format: "手机号格式不正确",
        remote: "手机号已被绑定"
      },
      'user[code]': {
        required: "验证码不能为空",
        minlength: "验证码只能为4位",
        maxlength: "验证码只能为4位"
      },
      'user[password]': {
        required: "密码不能为空",
        minlength: "密码不能少于6位",
        maxlength: "密码不能大于20位",
        format: "密码不能包含空格或特殊字符"
      }
    }
  });

  $('#bind_email_form').validate({
    rules: {
      'user[email]': {
        required: true,
        format: /^([^@\s]+)@((?:[a-z0-9-]+\.)+[a-z]{2,})$/i,
        remote: '/ajax/users/check_email'
      },
      'user[captcha]': {
        required: true,
        remote: '/ajax/users/check_captcha'
      }
    },
    messages: {
      'user[email]': {
        required: "电子邮箱不能为空",
        format: "电子邮箱格式不正确",
        remote: "该电子邮箱已被绑定"
      },
      'user[captcha]': {
        required: "请输入验证码",
        remote: "验证码错误，请重新输入"
      }
    }
  });

  // 个人设置-修改所在地
  area.liveClick();
  area.init();
})

// 所在地
var area = {
  init: function(){
    $('.selectoption li.active').each(function(){
      $(this).parents('.selectbox').find('input').val($(this).attr('data-value'));
      $(this).parents('.selectbox').find('label').text($(this).text());
    })

    $('.provinces li').on('click', function(){
      $.getScript('/ajax/region/cities?province_id=' + $(this).attr('data-value'));
    })
  },

  setValue: function(element){
    element.parents('.selectbox').find('input').val(element.attr('data-value'));
    element.parents('.selectbox').find('label').text(element.text());
    element.addClass('active').siblings().removeClass();
    element.parent().hide();
    return false;
  },

  liveClick: function(){
    $('.selectoption li').on('click', function(){
      area.setValue($(this));
      return false;
    })
  },

  updateCity: function(){
    var selected = $(".cities li.active");
    if(selected.length == 0){
      selected = $(".cities li:first");
    }
    selected.parents('.selectbox').find('input').val(selected.attr('data-value'));
    selected.parents('.selectbox').find('label').text(selected.text());
  }
}
