(function ($) {

  /**
  * Show caishuo alert dialog
  * @param [options] {{title, text}}
  * @param [e] {Event}
  */
  $.alert = function (options, e) {

    // 如果存在alert modal,则删除
    if ($('.alert-modal').length > 0){
      $('.alert-modal').remove();
    }

    var dataOptions = {};

    var settings = $.extend({}, $.alert.options, {
      close: function (o) {
        $(".alert-modal").fadeOut();
        $('body').removeClass('fixed');
      },
      button: null
    }, dataOptions, options);

    // Modal
    var modalHTML = 
    '<div id="FloatWindow" style="display: none;" class="alert-modal">' +
      '<div class="FloatContent width640" style="display: block;">' + 
        '<i class="close-window close"></i>' + 
        '<div class="header">' + 
          '<h2>' + settings.title + '</h2>' + 
        '</div>' + 
        '<div class="textbody center">' + settings.text + '</div>' + 
          '<div class="footer">' + 
          '<input type="button" class="b_btn dialog_btn_y close" value="确定">' + 
        '</div>' + 
      '</div>' +
    '</div>';

    var modal = $(modalHTML);

    modal.find(".close").click(function () {
      settings.close(settings.button);
    });

    // Show the modal
    $("body").append(modal);
    modal.fadeIn();
    $('body').addClass('fixed');
  };

  /**
  * 全局定义
  */
  $.alert.options = {
    text: "你确认吗?",
    title: "提示"
  }
})(jQuery);
