jQuery.validator.addMethod('format', function(value, element, param){
  return param.test(value);
}, "格式不正确");

jQuery.validator.addMethod('min', function(value, element, param){
  return (TextCheck(value) >= parseInt(param));
}, "长度太小");

// 可以为空，但是如果填写，必须大于多少
jQuery.validator.addMethod('min_can_blank', function(value, element, param){
  return (TextCheck(value) >= parseInt(param) || TextCheck(value) == 0);
}, "长度太小");

jQuery.validator.addMethod('max', function(value, element, param){
  return (TextCheck(value) <= parseInt(param));
}, "长度太大");


jQuery.validator.addMethod('light_required', function(value, element, param){
  return $('#user_email').val().length > 0
}, "请输入电子邮箱或昵称");

jQuery.validator.addMethod('password_remote', function(value, element, param){
  var result = false;
  $.ajax({
    async: false,
    url: '/ajax/users/check_email_or_name?email=' + $('#user_email').val() + '&username=' + $('#user_username').val(),
    dataType: 'json', 
    success: function(data){
      result = data;
    }
  })
  return result;
}, "电子邮箱或者昵称不正确");

jQuery.validator.addMethod('variety', function(value, element, param){
  var word = /[a-zA-Z]+/g;
  var digit = /\d+/g;
  var others = /[^a-zA-Z\d]+/g;
  var word_num = word.test(value) ? 1 : 0;
  var digit_num = digit.test(value) ? 1 : 0;
  var others_num = others.test(value) ? 1 : 0;
  return word_num + digit_num + others_num >= param;
}, "格式不正确");


jQuery.validator.addMethod('character', function(value, element, param){
  return !param.test(value);
}, "格式不正确");


jQuery.validator.setDefaults({
  errorElement: "span",
  errorClass: "err",
  focusInvalid: false,
  errorPlacement: function(error,element){
  $(element).parents('dd').find('.errorTip').remove();
    error.addClass('errorTip');
    element.parents('dd').append(error).end().next('.prompt').hide();
    console.log('done')
  },
  success: function(label,element){
    $(element).parents('dd').find('.errorTip').remove();
  }
});
