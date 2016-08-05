(function($){
  
  /** 
  * AutoComplete
  * @param [options] { source: callback, select: callback }
  * @param [e]  { Event }
  */
  $.fn.searchBox = function (options, e) {
    
    var $setting = $.extend({minlength: 1}, options)

    var $input = $(this).find('input.search');
    var $resBox = $(this).find('ul.searchresult');
     
    //$(this).find('kbd').click(function(){
    //  $input.trigger('focus');
    //})

    // 搜索框提示
    $input.bind('keyup', function(e){
      var len = $resBox.find('li').length;
      var cur = $resBox.find('.active').index();
      
      switch(e.keyCode){
        case 38:
          prevnext(-1);
        break;
        
        case 40:
          prevnext(1);
        break;
        
        case 13:
          $resBox.find('.active').click();
        break;
        
        default:
          if($.trim($(this).val()).length >= $setting.minlength){
            options.source(e.target);
          }else{
            $resBox.empty().fadeOut();
          }
      }
      
      // 上下移动
      function prevnext(step){
        if (cur == null){
          cur = (step<0)? len - 1:0;
        }else{
          cur = (len + 1 + cur + step) % (len + 1)
        }
        
        $resBox.find('li').removeClass().eq(cur).addClass('active');
        
      }

    })
    
    // Item选中之后执行函数
    $resBox.bind('click', function(e){
      if(options.select != undefined){
        var _target = $(e.target).is('li') ? $(e.target) : $(e.target).parents('li');
        options.select(_target);
      }else{
        return true;
      }
      $(this).fadeOut();
    })

  }


  // 高亮
  $.highlight = function(str, target_str){
    var regexp = new RegExp(target_str, "i");
    return str.replace(regexp, "<em>" + target_str.toUpperCase() + "</em>");
  }

})(jQuery);
