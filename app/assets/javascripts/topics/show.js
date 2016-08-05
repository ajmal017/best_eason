$(function(){
  $('.infoContent').contentPic({shrink: {id: '#---', classname: '',hook: function(){
            }},FloatBox: {id: '.FloatPicBox',dom: 'span',prev: 'prev',next: 'next'}});

  $(window).bind('scroll', function () {
      var headTop = $('#floatNavi').offset().top, headHeight = $('#floatNavi .navi').outerHeight(), $this = $(this);
      $('#floatNavi').toggleClass('floatNavi', $(window).scrollTop() > headTop).css('padding-top',$(window).scrollTop() > headTop?headHeight:0);
      $('#floatNavi .navi a[href^="#"]').each(function(){
          if ($(this).find('img').length >0) return;
          var link = $(this).attr('href').split('#')[1];
          var newTop = $('a[name="' + link + '"]').parent().offset().top - $('#floatNavi .navi').outerHeight();
          if ($this.scrollTop() > newTop){
              $('#floatNavi .navi a').removeClass('active');
              $(this).addClass('active');
          }
      });
  });
  $('.navi a').click(function () {
      var link = $(this).attr('href').split('#')[1];
      var newTop = $('a[name="' + link + '"]').parent().offset().top - $('#floatNavi .navi').outerHeight() +1;
      $(/firefox/i.test(window.navigator.userAgent) ? document.documentElement : 'body').animate({ scrollTop: newTop});
      return false;
  });
  $('#swapContent').click(function(){
      $('.infoContent').toggle();
      $(this).text($('.infoContent:visible').length?'收起':'查看更多');
      $(/firefox/i.test(window.navigator.userAgent) ? document.documentElement : 'body').animate({ scrollTop: $('.hot-title').offset().top});
  });


  $(document).on("mouseenter", ".j_stock_layer", function () {
    if($(this).find(".stockchart").attr("request-already") != "true"){
      var stock_id = $(this).attr("data-stock-id");
      var stockChart = $(this).find(".stockchart");
      $.get('/ajax/stocks/' + stock_id + '/chart', function(datas) {
        setStockChart(stockChart, datas);
        stockChart.attr("request-already", "true");
      })
    }
  })

  $(document).on('click', '.j_follow_basket', function(){
    followBasket(isLogined(), $(this).parents('li').attr('basket-id'), $(this));
    return false;
  })

  Topic.readedHandle(_topic_id.toString());

  Topic.increView();

  //锚点跳转
  if (window.location.hash){
    $(".navi a[href=" + window.location.hash + "]").trigger("click");
  }
})



var Topic = {
  increView: function(){
    $.post("/ajax/topics/"+_topic_id+"/incre_view")
  },

  readedHandle: function(topic_id){
    if (!this.isReaded(topic_id)){
      // $("#swapContent").click();
      $('.infoContent').toggle();
      $("#swapContent").text($('.infoContent:visible').length?'收起':'查看更多');
    }
    this.setReadedTopic(topic_id);
  },

  isReaded: function(topic_id){
    return this.readedIds().indexOf(topic_id) >= 0;
  },

  readedIds: function(){
    var ids_str = getCookie("readed_topic_ids");
    if (ids_str){
      return ids_str.split(",");
    }else{
      return [];
    }
  },

  setReadedTopic: function(topic_id){
    var readed_ids = this.readedIds();
    if (readed_ids.indexOf(topic_id) >= 0){
      readed_ids.remove(topic_id);
    }
    readed_ids.unshift(topic_id);
    setCookie("readed_topic_ids", readed_ids.slice(0, 50).join(","), 30);
  }
}

function setStockChart(obj, chart_datas) {
  $(obj).highcharts({
        global: {
          timezoneOffset: -480,
          useUTC: true
        },
        chart: {
          marginBottom: 15,
          marginTop: 17,
          marginLeft: 10,
          marginRight: 10,
          backgroundColor: '#4183c4',
          style: {
            fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
            fontSize: '12px'
          }
        },
        title: {
            text: null,
        },
        labels: {
          items: [{
            html: "<span>" + chart_datas.symbol + "</span>",
            style: {
                left: '10px',
                top: '0px',
                color: 'rgba(95, 155, 212, .9)',
                font: "font-weight: bold;font-size:14px;"
            }
          }]
        },
        xAxis: {
          categories: chart_datas.date,
          lineColor: 'rgba(255, 255, 255, .2)',
          tickColor: 'rgba(255, 255, 255, .4)',
          tickLength: 5,
          labels: {
            enabled: false
          }
        },
        credits: {
          enabled: false
        },
        yAxis: {
            gridLineWidth: 0
        },
        tooltip: {
          crosshairs: [
            {
                width: 1,
                color: 'rgba(56, 58, 76, .5)'
            }, 
            false
          ],
          backgroundColor: 'rgba(255, 255, 255, 0)',
          borderWidth: 0,
          shadow: false,
          style: {
            color: '#fff',
            fontSize: '12px',
            padding: '0px',
            margin: '0px'
          },
          formatter: function(){
            return chart_datas.unit + this.y;
          }
        },
        legend: {
          enabled: false
        },
        plotOptions: {
            series: {
                marker: {
                  radius: 2,
                  states: {
                        hover: {
                          radius: 4.5,
                          halo: false,
                          lineWidth: 0,
                          lineWidthPlus: 0
                        }
                    }
                },
                states: {
                  hover: {
                    halo: false,
                    lineWidth: 1,
                    lineWidthPlus: 0
                  }
                }
            }
        },
        series: [{
          data: chart_datas.datas,
          lineWidth: 1,
          color: 'rgba(255, 255, 255, 0.85)'
        }]
    });
}

//关注 or 取消关注
function followBasket(user_logined, basket_id, obj){
  if (user_logined){
    $.post("/ajax/baskets/" + basket_id + "/follow", {}, function(data){
      var follow_count_obj = $(obj).next().find(".concern").next();
      if (data.followed == true){
        $(obj).parent().addClass("favAdded");
      }else{
        $(obj).parent().removeClass("favAdded");
      }
    });
  }else{
    CaishuoAlert("请登录！");
  }
}
