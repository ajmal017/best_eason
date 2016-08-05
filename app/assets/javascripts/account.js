// @更新预览--废弃
var updatePreviewBackup = function(c){

  var boundx = $("#cropbox").width(),
  boundy = $("#cropbox").height(),

  large_preview = $('#large_preview'),
  large_preview_image = large_preview.find('img'), 

  small_preview = $('#small_preview'),
  small_preview_image = small_preview.find('img');


  if (parseInt(c.w) > 0){
    $('#user_crop_x').val(c.x);
    $('#user_crop_y').val(c.y);
    $('#user_crop_w').val(c.w);
    $('#user_crop_h').val(c.h);

    var rx = large_preview.width() / c.w;
    var ry = large_preview.height() / c.h;
    large_preview_image.css({
      width: Math.round(rx * boundx) + 'px',
      height: Math.round(ry * boundy) + 'px',
      marginLeft: '-' + Math.round(rx * c.x) + 'px',
      marginTop: '-' + Math.round(ry * c.y) + 'px'
    });

    var sx = small_preview.width() / c.w;
    var sy = small_preview.height() / c.h;
    small_preview_image.css({
      width: Math.round(sx * boundx) + 'px',
      height: Math.round(sy * boundy) + 'px',
      marginLeft: '-' + Math.round(sx * c.x) + 'px',
      marginTop: '-' + Math.round(sy * c.y) + 'px'
    });
  }
};

// @设置预览图
var setPreviewImage = function(src){
  var image_content = "<img src='"+src+"' id='cropbox'></img>";
  $("#origin_preview").html(image_content);
  $("#large_preview img").attr('src', src);
  $("#small_preview img").attr('src', src);
}

// 刷新验证码
var refresh_captcha = function(){
  var current_date = new Date();
  var captcha_url = "/captcha?i=" + current_date.getTime().toString();
  $("#img_captcha").attr("src", captcha_url);
}

// 显示裁剪框
var showCropModal = function(){
  $("#j_crop_logo").modal('show');
  $(".modal-body").find('p').empty();
}

$(function(){

  // iframe 不刷新提交文件
  $("#real_avatar").change(function(){
    var currentForm = $(this).parents("form");
    if($("iframe[name='curform']").length > 0){
      var thisIframe = $("iframe[name='curform']");
    }else{
      var thisIframe = $("<iframe style='opacity:0;_filter:alpha(opacity=0)'></iframe>").attr("name",currentForm.attr("target"));
    }
    $(currentForm).after(thisIframe);
    $(currentForm).submit();
    showCropModal();
  });

  // 初始化jcrop
  userJcropInit();

  $("#j_new_user input:not(:checkbox)").focus(function(){
    $(this).parents('.form-group').removeClass('has-error')
    .find('label.info-label').text(function(index, element){
      return $(this).attr('notice');
    }).show();
    $(this).next('.cs-form-icon-ok').hide();
  })

  // 财说服务协议
  $("#j_protocol_div").on('click', function(){
    protocol_img = $("#j_protocol_img")
    if(protocol_img.is(':hidden')){
      protocol_img.show();
      $(".j_protocol_err_text").hide();
    }else{
      protocol_img.hide();
      $(".j_protocol_err_text").show();
    }
  })

  // 确认密码显示
  $("#user_password").focus(function(){
    confirmation_group = $("#user_password_confirmation").parents(".form-group")
    if(confirmation_group.is(':hidden')){
      confirmation_group.show();
    }  
  })

  // 注册页面提交
  $("#j_new_user").submit(function(){
    if($("#j_protocol_img").is(":hidden")){
      $(".j_protocol_err_text").show();
      return false;
    }else{
      $(".j_protocol_err_text").hide();
      return true;
    }
  })

  // 注册第一个页面前段验证
  $("#j_new_user").validate({
    rules: {
      'user[username]': {
        required: true,
        minlength: 4,
        maxlength: 16,
        remote: '/ajax/users/check_username'
      },
      'user[email]': {
        required: true,
        format: /^([^@\s]+)@((?:[a-z0-9-]+\.)+[a-z]{2,})$/i,
        remote: '/ajax/users/check_email'
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
      },
      'user[captcha]':{
        required: true,
        remote: '/ajax/users/check_captcha'
      }
    },
    messages: {
      'user[username]': {
        required: "昵称不能为空",
        minlength: "昵称最少4位",
        maxlength: "昵称最多16位",
        remote: "昵称已经存在"
      },
      'user[email]': {
        required: "邮箱不能为空",
        format: "邮箱格式不正确",
        remote: "邮箱已经存在"
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
        equalTo: "和原始密码不一致"
      },
      'user[captcha]': {
        required: "请输入图片验证码",
        remote: "验证码不正确"
      }

    }
  })

  // 重新发送激活邮件
  $("#j_resend_confirmation_email").on('click', function(){
    $("#j_confirmation_form").submit();
    return false;
  });

})



