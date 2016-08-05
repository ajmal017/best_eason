(function ($) {

  /**
  * Show a confirmation dialog
  * @param [options] {{title, text, confirm, cancel, confirmButtonClass}}
  * @param [e] {Event}
  */
  $.confirm = function (options, e) {
    
    // Delete dialog when active confirm modal.
    if ($('.confirmation-modal').length > 0){
      $('.confirmation-modal').remove();
    }

    // Default options
    var settings = $.extend({}, $.confirm.options, {
      cancel: function (o) {
        $(".confirmation-modal").fadeOut();
        $('body').removeClass('fixed');
      },
      button: null
    }, {}, options);

    // Modal
    var modalHTML = 
    '<div id="FloatWindow" style="display: none;" class="confirmation-modal">' +
      '<div class="FloatContent" style="display: block;">' + 
        '<i class="close-window cancel"></i>' + 
        '<div class="header">' + 
          '<h2>' + settings.title + '</h2>' + 
        '</div>' + 
        '<div class="textbody">' + settings.text + '</div>' + 
        '<div class="footer">' + 
          '<a href="javascript:void(0);" class="btn confirm ' + settings.confirmButtonClass + '">' + settings.confirmText + '</a> &nbsp;' + 
          '<a href="javascript:void(0);" class="btn cancel ' + settings.cancelButtonClass + '">' + settings.cancelText + '</a>' + 
        '</div>' + 
      '</div>' +
    '</div>';

    var modal = $(modalHTML);

    modal.find(".confirm").click(function () {
      settings.cancel(settings.button);
      settings.confirm(settings.button);
    });
    
    modal.find(".cancel").click(function () {
      settings.cancel(settings.button);
    });

    // Show the modal
    $("body").append(modal);
    modal.fadeIn();
    $('body').addClass('fixed');
  };

  /**
  * Globally definable rules
  */
  $.confirm.options = {
    text: "你确认吗?",
    title: "提示",
    confirmText: '确定',
    cancelText: '取消',
    confirmButtonClass: "large",
    cancelButtonClass: "large"
  }
})(jQuery);
