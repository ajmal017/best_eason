//公用
$(function(){
  reloadPrize();

  window.setInterval(function(){
    reloadPrize();
  }, 300000)
})

function reloadPrize(){
  $.get("/ajax/data/contest_cash", {}, function(response){
    setPoll(response.cash, response.trading == true ? response.timestamp : "0");
  })
}


// index 页面
var Contest = {
  handler: function(){
    window.setInterval(function(){
      loadTradingInfos("index");
    }, 5000);

    $(".btn-focus").click(function(){
      if ($(this).attr("status") == "following") return;
      $(this).attr("status", "following");
      var user_id = $(this).parent().parent().attr("data-user-id");
      followUser(user_id);
    })

    $(".focus").click(function(){
      if ($(this).attr("status") == "following") return;
      $(this).attr("status", "following");
      var user_id = $(this).parent().parent().attr("data-user-id");
      followUser(user_id);
    })

    // 报名参赛
    $('#registerMatch').click(function(){
        var that = this;
        $.post("/ajax/contests/"+_contest_id+"/sign_next", {}, function(){
          CaishuoDialog.open({theme:'alert',title:'报名申请', content:'<span style="color:#448cd3;">我们已经收到您的请求，</span><br/><span style="font-size:14px;">请期待我们与您联络。</span>',btnclass:{confirm:'btn btn-blue'},callback:function(){
              $(that).hide();
              $('.assigned').addClass('active');
          }});
        })
        
    });
  }
}

function followUser(user_id){
  $.post("/ajax/users/"+user_id+"/toggle_follow", {}, function(response){
    if (response.followed){
      $("tr[data-user-id="+user_id+"]").find(".focus").addClass("active").attr("status", '');
      $(".top3 dd[data-user-id="+user_id+"]").find(".btn-focus").text("已关注").attr("status", '');
    }else{
      $("tr[data-user-id="+user_id+"]").find(".focus").removeClass("active").attr("status", '');
      $(".top3 dd[data-user-id="+user_id+"]").find(".btn-focus").text("+ 关注").attr("status", '');
    }
  })
}

//交易信息页面
function newTradingInfo(record){
    var maxlen = 60, itemnum = $('#tradeRecordList tbody tr').length;
    if (itemnum < maxlen && itemnum % 10 == 0){
        $('#tradeRecordList > div:eq(0)').clone().appendTo('#tradeRecordList').find('tbody').empty();
    }
    $(formatRecord(record)).prependTo('#tradeRecordList tbody:eq(0)').animate({opacity:1},800);
    $('#tradeRecordList > div').each(function(){
        var $next = $(this).next().find('tbody'),
            $nextAll = $(this).find('tbody tr').eq(9).nextAll();
        if ($next.length) {
            $nextAll.prependTo($next);
        }else{
            $nextAll.remove();
        }
    });
}

function loadTradingInfos(page){
  if (page == "index"){
    var last_od_id = $("#TradingInfo tbody tr:first").attr("data-id");
  }else{
    var last_od_id = $("#tradeRecordList tbody tr:first").attr("data-id");
  }
  
  $.getJSON("/events/shipan/trading.json", {last_id: last_od_id}, function(response){
    var datas = response.datas,
        length = datas.length;
    $.each(datas, function(index){
      newTradingInfo(datas[length - index - 1]);
    })
  })
}


//排名页面
function setLoading(){
  $(".btn-more").attr("data-status", "loading").text("加载中...");
}

function setLoaded(){
  $(".btn-more").attr("data-status", "loaded").text("加载更多");
}

function setNoMore(){
  $(".btn-more").attr("data-status", "loading").text("没有更多了");
}
