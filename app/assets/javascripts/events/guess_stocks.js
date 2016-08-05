// 股票搜索 - 结束
// 用法示例: $('#StockSearch').StockSearch();
$.fn.StockSearch = function() {
  return $(this).each(function() {
    var $input = $(this).find('input');
    var $resBox = $(this).find('ul').on('mouseenter', 'li', function(e) {
      $(this).addClass('active').siblings().removeClass('active');
    });
    $input.bind('input keyup click focus', function(e) {
      var key = $(this).val().trim().split('(')[0],
        last = $(this).attr('data-last');
      if (key.length == 0) {
        $resBox.hide();
        return false;
      }
      if (key != last) {
        $('.StockSearch button').addClass('disabled');
        $(this).attr('data-last', key);

        $.get('/ajax/global/stock_search', {
          q: key
        }, function(data) {
          // 更新搜索结果列表前先判断关键字是否匹配
          if ($input.attr('data-last') !== data.q)
            return;

          $resBox.empty();
          if (data.stocks.length) {
            for (var i = 0, dlen = data.stocks.length; i < dlen; i++) {
              var item = data.stocks[i];
              $resBox.append('<li class="item">' + item.text.replace(/<\/em><em>/g, '') + '</li>');
            }
          } else {
            $resBox.append('<li class="label">没有找到相关的股票</li>');
          }
        });

      }

      $resBox.show();
      return false;
    });
    $(window).click(function() {
      $resBox.hide();
    });
  });
};
$('#StockSearch').StockSearch();

$('#StockSearch ul').on('click', 'li', function() {
  var $this = $(this);
  var text = $this.text().trim();
  if (text.search(/\(/) >= 0) {
    $this.closest('ul').siblings('input').val(text);
    $('.StockSearch button').removeClass('disabled');
  }
});
// 股票搜索 - 结束

if (!isLogin) {
  showtip('', '参与竞猜请先登录！', '立即登录');
  // showtip('提交成功', '收盘后开奖，祝你好运！', '确定');
}

var submited = false;

function showtip(title, txt, btn) {
  var $tip = $('#tip');
  var btn_txt = "重新猜";

  if (typeof(title) == "string" && title.length > 0)
    $tip.find('em').text(title);
  else
    $tip.find('em').addClass('hide');

  if (btn != undefined)
    btn_txt = btn;

  $('body').addClass('tip');
  $tip.show().find('label').text(txt);

  $('#tip span').text(btn_txt);
}
$('#tip span').click(function() {
  if ($('#tip span').text().trim() == "立即登录") {
    Caishuo.trigger('sendback', {
      'event': 'forcelogin',
      'status': 'authfailed'
    });
    isLogin = true;
  }else if (submited) {
    window.location.reload();
  } else {
    $('body').removeClass();
    $('#tip').hide();
    $('#content .enter input').focus();
  }
});

$('.enter button').click(function() {
  if ($(this).hasClass('disabled')) {
    $('input').focus();
    return;
  }

  var val = $(this).prev('input').val().trim();
  if (val.search(/\d+(\.(sh|sz))*/i) < 0) {
    showtip('输入错误', '请输入正确的股票代码，如601988.sh、000333.sz', '确定');
  } else {
    // do real job here
    var symbol = val.split('(')[1].replace(')', ''),
        token = $("meta[name='csrf-token']").attr("content");
    $.post(guessPostPath, {symbol: symbol, authenticity_token: token}, function(response){
      submited = true;
      showtip('提交成功', '收盘后开奖，祝你好运！', '确定');
    })
  }
});

Caishuo.connect("event", function() {
  $('.share').on('click', function() {
    // $(this).addClass('hide');
    Caishuo.trigger('sharepage', {
      'title': '',
      'content': '属于股民的万圣趴！天天抓妖股，最高中5000元！',
      'link': shareLink,
      'picture': sharePicUrl
    });
  });
});

$('.top5 .content ul').on('click', 'li', function() {
  $(this).addClass('active').siblings().removeClass('active');
  $('.tabs-body').children().eq($(this).index()).addClass('active').siblings().removeClass('active');
});