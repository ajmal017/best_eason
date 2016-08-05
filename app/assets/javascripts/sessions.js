$(function(){
  // 登录记住密码
  $("#j_remember_div").on('click', function(){
    var remember_me_img = $("#j_remember_img");
    if(remember_me_img.is(':hidden')){
      remember_me_img.show();
      $("#user_remember_me").attr('checked', true);
    }else{
      remember_me_img.hide();
      $("#user_remember_me").attr('checked', false);
    }
  })

})
