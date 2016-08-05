//=require opinion

$(function(){
  
  BasketChart.setChartOpions();
  BasketChart.setBasketReturnChart(_basket_id);

  $("#time_period_btns .peroid").on("click", function(){
    $(this).addClass("active").siblings().removeClass("active");
    BasketChart.clicked_period = true;
    BasketChart.setChartExtremes($(this).attr("data"));
  })

  BasketShow.followHandler();

  $(window).scroll(function(){
    InfosNav.listenerForWindowScrollEvent();
  })

  $(".j_adjust_records").on("click", function(){
    $.get("/baskets/"+_basket_id+"/adjust_logs");
  })

  $('.sortcolumn').columnsortable();
  $('.tbdiv .themeStocks').sectorPie(weights_data);
  $('.tbdiv .themeStocks tfoot .scrollBar').slider({
      range:'min',
      min:0,
      max:1000,
      value:0,
      disabled:true
  }).slider("value", weights_data.cash * 1000);


  $(document).on("click", ".likeable", function(){
    Comment.likeComment($(this));
  })

  $(document).on("click", ".replyable", function(){
    Comment.replyComment(this);
  })

  $(document).on("click", ".remove_comment", function(){
    Comment.deleteComment(this);
  })
  
  BasketShow.incrementBasketPageView(_basket_id);
})

//
// methods at show page
//
var BasketShow = {
  //增加view count
  incrementBasketPageView: function(basket_id){
    $.post("/ajax/baskets/" + basket_id + "/increment_view");
  },

  followHandler: function(){
    $("#follow_basket.btn_theme_c a, #follow_basket.btn_theme_a").on("click", function(){
      BasketShow.followBasket(_basket_id);
    })
  },

  followBasket: function(basket_id){
    var follow_btn = $("#follow_basket");
    if (!follow_btn.hasClass("loading")){
      follow_btn.addClass("loading");
      $.post("/ajax/baskets/" + basket_id + "/follow", {}, function(data){
        if (data.followed==null) return;

        var follow_count_em = $("#follow_basket").prev("em"),
            follow_count = parseInt(follow_count_em.text()),
            share_obj = $("#follow_basket").next("a");
        follow_btn.remove();
        if (data.followed == true){
          share_obj.before('<span id="follow_basket" class="w_btn btn_theme_c btn_dropDown">已关注<a href="javascript:" >取消关注</a></span>');
          follow_count_em.text(follow_count+1);
        }else{
          share_obj.before('<span id="follow_basket" class="w_btn btn_theme_a">关注</span>');
          follow_count_em.text(follow_count-1);
        }
        BasketShow.followHandler();
      });

    }
  },

  editBasket: function(){
    window.location.href =  "/baskets/" + _basket_id + "/add";
  }

}

//
// 个股详情弹出层方法
//
var StockDetail = {
  stock_infos: {},

  show: function(stock_id, callback){
    var stock_datas = StockDetail.stock_infos[stock_id];
    if (stock_datas != undefined){
      StockDetail.showInfosHtml(stock_id, stock_datas);
      callback($('#stockTipBox').children().clone(true), {gap: -1});
      StockDetail.initStock52WeekPriceChart(stock_datas.prices_in_52_weeks);
    }else{
      $.get("/ajax/stocks/" + stock_id + "/infos", {basket_id: _basket_id}, function(datas){
        StockDetail.stock_infos[stock_id] = datas;
        StockDetail.showInfosHtml(stock_id, datas);
        callback($('#stockTipBox').children().clone(true), {gap: -1});
        StockDetail.initStock52WeekPriceChart(datas.prices_in_52_weeks);
      })
    }
  },

  showInfosHtml: function(stock_id, infos){
    var html = '<dl class="stockTip">';
    html += '<dd><a target="_blank" href="/stocks/' + stock_id + '">' + infos.company_name + ' - ' + infos.symbol + '</a></dd>';
    html += '<dt>入选理由</dt>';
    html += '<dd>' + infos.basket_stock_notes + '</dd>';
    html += '<dt>基本信息</dt>';
    html += '<dd><ul class="clearfix">';
    html += '<li>最后价/变动%<strong>' + infos.unit + infos.latest_price;
    html += this.upOrDownStyle(infos.returns['one_day'], '%') + '</strong></li>';
    html += '<li>52周最高最低';
    html += '<table><tr><th colspan="2">';
    html += '<div class="trend-pic tooltip_chart" style="width:113px;height:40px;margin-left:5px;"></div></th></tr>';
    html += '<tr class="small"><td align="left">' + infos.unit + this.minValue(infos.prices_in_52_weeks) + '</td>';
    html += '<td align="right">' + infos.unit + this.maxValue(infos.prices_in_52_weeks) + '</td></tr>';
    html += '<tr><td colspan="2"><div class="chartPosBar"><span style="left:' + this.bluePointPosition(infos.prices_in_52_weeks) + '%;"></span></div>';
    html += '</td></tr></table></li>';
    html += '<li>回报<table><tr><td>1月:</td>';
    html += '<th>' + this.upOrDownStyle(infos.returns['one_month'], '%') + '</th></tr>';
    html += '<tr><td>6月:</td><th>' + this.upOrDownStyle(infos.returns['six_month'], '%') + '</th></tr>';
    html += '<tr><td>1年:</td><th>' + this.upOrDownStyle(infos.returns['one_year'], '%') + '</th></tr>';
    html += '</table></li></ul></dd>';
    html += '<dd class="ratenum"><span>市值 : ';
    html += infos.market_capitalization == "" ? "--" : infos.market_capitalization;
    html += '</span> <span>市盈率 : ';
    html += infos.pe_ratio == "" || infos.pe_ratio==0 ? "--" : parseFloat(infos.pe_ratio).round(2);
    html += '</span></dd>';
    html += '<dd>' + infos.com_intro + '</dd>';
    html += '</dl>';

    $("#stockTipBox").html("").html(html);
  },

  initStock52WeekPriceChart: function(chart_datas){
    $("#BubbleBox .tooltip_chart").highcharts({
        chart: {
          marginBottom: 0,
          marginTop: 0,
          marginLeft: 0,
          marginRight: 0,
          backgroundColor: '#f6f6f6'
        },
        title: {
          text : null
        },
        credits: {
          enabled: false
        },
        xAxis: {
            type: 'datetime',
            labels: {
              enabled: false
            },
            offset: 0
        },
        yAxis: {
            labels: {
              enabled: false
            },
            title: {
              enabled: false
            },
            offset: -70,
            gridLineWidth: 0
        },
        tooltip: {
            formatter: function(){
              return this.y;
            }
        },
        legend: {
            enabled: false
        },
        plotOptions: {
            area: {
                fillColor: '#EBEAEA',
                color: '#3da1df',
                lineWidth: 1,
                marker: {
                    enabled: false
                },
                shadow: false,
                states: {
                    hover: {
                        lineWidth: 1
                    }
                },
                threshold: null
            }
        },
        series: [{
            type: 'area',
            name: '52week prices',
            pointInterval: 24 * 3600 * 1000,
            data: chart_datas
        }]
    })
  },

  upOrDownStyle: function(value, unit){
    if (value == null || value == undefined){
      return "--";
    }

    if (value >= 0){
      return '<em class="plus">+' + value + unit + '</em>';
    }else{
      return '<em class="mins">' + value + unit + '</em>';
    }
  },

  maxValue: function(arr){
    return Math.max.apply(null, arr);
  },

  minValue: function(arr){
    return Math.min.apply(null, arr);
  },

  //个股趋势图下面的小圆点
  bluePointPosition: function(prices){
    var max_val_index = prices.indexOf(this.maxValue(prices)) + 1;
    return max_val_index*100/prices.length;
  }

}

//
// 中间导航交互效果
//
var InfosNav = {
  nav_height: 64,

  listenerForWindowScrollEvent: function(){
    // this.listenerForNavPosition();
    this.listenerForNavMenuStyle();
  },

  listenerForNavMenuStyle: function(){
    var adjusted_top = $(window).scrollTop() + this.nav_height;
    this.clearNavLiClass();
    if (adjusted_top < this.stocksOffsetTop()){
      $("#nav_basic_info").addClass("active");
    }else if (adjusted_top >= this.stocksOffsetTop() && adjusted_top < this.commentsOffsetTop()){
      $("#nav_stocks").addClass("active");
    }else if (adjusted_top >= this.commentsOffsetTop()){
      $("#nav_comments").addClass("active");
    }
  },

  clearNavLiClass: function(){
    $(".asNav span a").removeClass("active");
  },

  basicInformationOffsetTop: function(){
    return $("#basic_info").offset().top;
  },

  stocksOffsetTop: function(){
    return $("#stock-portfolio").offset().top;
  },

  commentsOffsetTop: function(){
    return $("#review").offset().top;
  },

  navLiClickEvent: function(obj){
    var div_class = $(obj).attr("goto");
    var scroll_val = $(".details ." + div_class).offset().top - this.nav_height;
    $(window).scrollTop(scroll_val);
  }
}

//评论
var CommentExt = {
  getCommentsByPage: function(page){
    $.get("/baskets/" + _basket_id + "/comments", {page: page}, function(){})
  },

  scrollWhenPageChanged: function(){
    $(window).scrollTop($(".comments").offset().top - 63);
  },

  // opinionsHandle: function(){
    
  // },

  getOpinionersAvatar: function(type){
    $.get("/ajax/baskets/"+_basket_id+"/opinioners", {type: type}, function(response){
      $("#opinioner_avatars li").remove();
      $.each(response.avatars, function(){
        var li_html = '<li><a class="j_bop" href="javascript:;" data-uid="' + this[0] + '"><img src="' + this[1] + '" /></a></li>';
        $("#opinioner_avatars").append(li_html);
      })
      if (response.baskets_infos != undefined){
        $("#related_baskets").html("");
        $.each(response.baskets_infos, function(){
          var a_html = '<a target="_blank" href="/baskets/'+this.id+'">'+this.title+'</a>';
          $("#related_baskets").append(a_html);
        })
      }
      if (response.opinioners_count != undefined){
        $("#opinioners_count").text(response.opinioners_count);
      }
      initBubbleBox();
    })
  }
}


//
// methods for basket return charts
//
var BasketChart = {
  chartDatas: [],
  chart: undefined,
  clicked_period: false,
  market_name: null, 
  motif_line_dash_style: '',
  motif_simulated: false,

  //初始化chart
  setBasketReturnChart: function(basket_id){
    $.get('/ajax/baskets/' + basket_id + "/chart_datas", {}, function(datas) {
      BasketChart.chartDatas = datas;
      BasketChart.market_name = datas.market_name;
      var end_timestamp = (new Date()).getTime();
      var start_timestamp = parseInt($("#time_period_btns .active:first").attr("data"));
      var adjusted_datas = BasketChart.adjustedReturnDatasForChart(start_timestamp, end_timestamp);
      BasketChart.initReturnChart(datas.market_data, adjusted_datas);
    });
  },

  adjustedReturnDatasForChart: function(start_timestamp, end_timestamp){
    var datas = {};
    datas['market_data'] = BasketChart.calculateReturnDatas(BasketChart.chartDatas.market_data, start_timestamp, end_timestamp);
    if (BasketChart.chartDatas.created_timestamp > start_timestamp){
      var basket_datas = BasketChart.chartDatas.simulated;
      BasketChart.motif_line_dash_style = 'ShortDot';
      BasketChart.motif_simulated = true;
    }else{
      var basket_datas = BasketChart.chartDatas.basket;
      BasketChart.motif_line_dash_style = '';
      BasketChart.motif_simulated = false;
    }
    datas['basket'] = BasketChart.calculateReturnDatas(basket_datas, start_timestamp, end_timestamp);
    return datas;
  },

  calculateReturnDatas: function(ori_datas, start_timestamp, end_timestamp){
    var datas = [];
    var adjust_datas = [];
    $.each(ori_datas, function(){
      if(this[0] >= start_timestamp && this[0] <= end_timestamp){
        datas.push(this);
      }
    })
    $.each(datas, function(){
      var change_percent = (this[1] - datas[0][1])*100/datas[0][1];
      adjust_datas.push([this[0], change_percent]);
    })
    return adjust_datas;
  },

  //只更新chart的数据
  updateChartSeriesData: function(start_timestamp, end_timestamp){
    var adjusted_datas = BasketChart.adjustedReturnDatasForChart(start_timestamp, end_timestamp);
    var added_points = [[BasketChart.chartDatas.market_data[0][0], 0]];
    BasketChart.chart.series[1].setData(added_points.concat(adjusted_datas.market_data), false);
    BasketChart.chart.series[0].setData(adjusted_datas.basket, false);
    BasketChart.chart.redraw();
    BasketChart.setChartReturnLabel();
    BasketChart.changeMotifLineDashStyle();
  },

  initReturnChart: function(navigator_data, datas){
    $('#basket_chart').highcharts('StockChart', {
      global: {
        timezoneOffset: -480,
        useUTC: false
      },

      chart: {
        style: {
          fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
          fontSize: '12px'
        },
        panning: false,
        marginLeft: 0,
        spacingBottom: 0
      },

      rangeSelector : {
        inputDateFormat : "%Y-%m-%d",
        buttons: [],
        buttonSpacing: 10,
        inputStyle: {
          outline: 0,
          fontSize: 12,
          paddingTop: 15
        },
        inputBoxBorderColor: '#b9c3ce',
        inputBoxWidth: 90,
        inputBoxHeight: 21,
        labelStyle: {
          color: '#0b1318',
          fontWeight: 'bold'
        }
      },

      plotOptions: {
          series: {
              animation: {
                  duration: 1000,
                  easing: 'swing'
              }
          }
      },

      title: {
        text : null
      },
      
      credits: {
        enabled: false
      },

      labels: {
        items: [{
          html: "<span>-</span>",
          style: {
              left: '0px',
              top: '7px',
              color: 'red'
          }
        }]
      },
      
      xAxis: {
        dateTimeLabelFormats : {
          day: '%m-%d',
          week: '%m-%d',
          month: '%m月',
          year: '%Y年'
        },
        events: {
          afterSetExtremes: function(e) {
            BasketChart.clearChartBtnActive();
            var start_timestamp = e.min;
            var end_timestamp = e.max;
            BasketChart.updateChartSeriesData(start_timestamp, end_timestamp);
          }
        },
        minRange: 1
      },
      
      yAxis: {
        opposite: true,
        offset: -15,
        labels: {
          align: 'right',
          formatter: function() {
            if (this.isLast){
              return '';
            }else{
              return calPrefix(this.value) + this.value +'%';
            }
          }
        },
        showLastLabel: false
      },

      navigator: {
        series: {
          data: navigator_data
        },
        adaptToUpdatedData: false
      },
      
      tooltip: {
        xDateFormat: "%Y-%m-%d",
        positioner: function(boxWidth, boxHeight, point) {
          var chart = this.chart;
          if((point.plotX+boxWidth) >= chart.plotWidth){
            return { x: point.plotX - boxWidth, y: chart.plotTop + point.plotY};
          }
          return { x: point.plotX, y: chart.plotTop + point.plotY};
        },
        shared: true,
        useHTML: true,
        style: {
          padding: '12px'
        },
        borderColor:'#dfdfdf',
        backgroundColor: 'rgba(255, 255, 255, 0.85)',
        shadow: false,
        valueDecimals: 2,
        formatter: function() {
          var s = '<b style="line-height: 25px;">' + Highcharts.dateFormat('%Y-%m-%d', this.x) + '</b>';
          $.each(this.points, function(i, point) {
            if (point.series.index == 0){
              s += '<br/><span style="line-height: 25px;">' + point.series.name + BasketChart.motifSimulatedNotification() + '：<span style="color:' + BasketChart.tooltipFontColor(point.y) + '">' + calPrefix(point.y) + point.y.toFixed(2) + ' %</span></span>';
            }else{
              s += '<br/><span style="line-height: 25px;">' + point.series.name + '：<span style="color:' + BasketChart.tooltipFontColor(point.point.y) + '">' + calPrefix(point.point.y) + point.point.y.toFixed(2) + ' %</span></span>';
            }
          })
          return s;
        }
      },
    
      series: [
        {
          name : '本投资主题',
          data : datas.basket,
          tooltip: {
            valueDecimals: 2
          },
          type: 'line',
          connectNulls: true,
          dashStyle: BasketChart.motif_line_dash_style,
          color: "#87bdee"
        },
        {
          name : BasketChart.market_name,
          data : datas.market_data,
          tooltip: {
            valueDecimals: 2
          },
          color: "#7DCD6D"
        }]
    }, function(chart) {
        setTimeout(function () { 
          BasketChart.chart = $('#basket_chart').highcharts();
          BasketChart.setChartReturnLabel();
          BasketChart.adjustDateInputTextStyle();
        }, 0);
    });
  },

  setChartExtremes: function(begin_timestamp){
    var today = new Date();
    BasketChart.chart.xAxis[0].setExtremes(begin_timestamp, today.getTime() + 8*3600*1000);
  },

  dateStrToTimestamp: function(date_str){
    return (new Date(date_str)).getTime();
  },

  clearChartBtnActive: function(){
    if (!this.clicked_period){
      $("#time_period_btns .peroid").removeClass("active");
    }else{
      this.clicked_period = false;
    }
  },

  motifLegend: function(){
    this.legendControl(0);
  },

  sp500Legend: function(){
    this.legendControl(1);
  },

  hsLegend: function(){
    this.legendControl(1);
  },

  legendControl: function(series_index){
    var series = BasketChart.chart.series[series_index];
    if (series.visible) {
      series.hide();
    } else {
      series.show();
    }
  },

  chartReturnLabelClear: function(){
    $("text tspan:eq(0)").html(" ");
  },

  setChartReturnLabel: function(){
    var return_percent = BasketChart.chart.series[0].yData.slice(-1)[0].toFixed(2);
    var peroid_desc = $("#time_period_btns .active").text();
    if (peroid_desc == ""){
      this.chartReturnLabelClear();
    }else{
      var prefix = calPrefix(parseFloat(return_percent));
      this.chartReturnLabel(peroid_desc + "回报：" + prefix + return_percent + "%", BasketChart.tooltipFontColor(parseFloat(return_percent)));
    }
  },

  chartReturnLabel: function(html, color){
    $("text tspan:eq(0)").text(html);
    $("text tspan:eq(0)").parent().css("color", color).css("fill", color);
  },

  changeMotifLineDashStyle: function(){
    BasketChart.chart.series[0].update({dashStyle: BasketChart.motif_line_dash_style});
  },

  motifSimulatedNotification: function(series_name){
    return BasketChart.motif_simulated ? '(预估的)' : '';
  },

  adjustDateInputTextStyle: function(){
    $(".highcharts-input-group g:eq(1)").find("text").attr("y", 17);
    $(".highcharts-input-group g:eq(2)").find("text").attr("y", 17).attr("x", "0");
    $(".highcharts-input-group g:eq(3)").find("text").attr("y", 17);
  },

  tooltipFontColor: function(value){
    return value>=0 ? "red" : "green";
  },

  setChartOpions: function(){
   
    Highcharts.setOptions({
      lang : {
        rangeSelectorFrom : "",
        rangeSelectorTo : "至",
        rangeSelectorZoom : ""
      }
    });
  }

}



// 大赛专用页面js
function loadTradingInfos(){
  var last_od_id = $(".trends tbody tr:first").attr("data-id");
  $.getJSON("/events/shipan/trading.json", {last_id: last_od_id}, function(response){
    var datas = response.datas,
        length = datas.length;
    $.each(datas, function(index){
      newTradingInfo(datas[length - index - 1]);
    })
  })
}

function newTradingInfo(record){
    $(formatRecord(record)).prependTo('.trends tbody').animate({opacity:1},800);
    $('.trends tbody tr:eq(9)').nextAll().remove();
}

function formatRecord(record){
    return '<tr style="opacity:0.1;" data-id="%id%""><td></td><td><a href="/baskets/%basket_id%" class="limitLength" target="_blank">%user_name%</a></td><td class="%trade_class%">%trade_method%</td><td><a href="/stocks/%stock_id%" target="_blank">%stock_name%</a></td><td>%trade_price%</td><td>%trade_time%</td><td></td></tr>'
        .replace(/%id%/g, record.id)
        .replace(/%basket_id%/g, record.basket_id)
        .replace(/%user_id%/g,record.user_id)
        .replace(/%user_name%/g,record.user_name)
        .replace(/%trade_class%/g,record.trade_action=='sold'?'mins':'plus')
        .replace(/%trade_method%/g,record.trade_action=='sold'?'卖出':'买入')
        .replace(/%stock_id%/g,record.stock_id)
        .replace(/%stock_name%/g,record.stock_name)
        .replace(/%trade_price%/g,record.trade_price)
        .replace(/%trade_time%/g,record.trade_time);
}


function loadOrderDetails(page, account){
  $.get("/accounts/"+account+"/order_details", {page: page})
}






//前端人员js

$(document).on("click", ".close-window", function () {
    $("#FloatWindow").hide();
})
$(document).on("click", ".record ul li i.open", function () {
    var thisBox= $(this).next().next(".record_content");
    if (!thisBox.is(":visible")) {
        $(".record ul li i.open").removeClass('click').next().next(".record_content").hide();
    }
    thisBox.toggle();
    $(this).toggleClass('click');
});

$(function () {
  // 分享
  var shareTimer;
  $("#weChat_share,.share").hover(function(){
      clearTimeout(shareTimer);
      $(".share").show();
  },function(){
      shareTimer = setTimeout(function () {
          $(".share").hide();
      }, 400);
  });
  // 滚动导航
  $(window).bind('scroll', function () {
    if ($('#navCanFloat').offset() == undefined) return;
      var headTop = $('#navCanFloat').offset().top;
      $('#navCanFloat').toggleClass('navFloat', $(window).scrollTop() > headTop);
  });
  $('.asNav a').click(function () {
      var link = $(this).attr('href').split('#')[1];
      var newTop = $('a[name="' + link + '"]').css('display', 'block').position().top - $('.asNav').outerHeight();
      $('.asNav a').removeClass('active');
      $(this).addClass('active');
      $(/firefox/i.test(window.navigator.userAgent) ? document.documentElement : 'body').animate({ scrollTop: newTop +2 + 'px' });
      return false;
  });

  // 正文图片
  var arg = {
      shrink: {
          id: '#shrink',
          classname: 'shrinked',
          hook: function () {$('a[href="#basicInfo"]').trigger('click'); }
      },
      FloatBox: {
          id: '.FloatPicBox',
          dom: 'span',
          prev: 'prev',
          next: 'next'
      }
  };
  $('.infoContent').contentPic(arg);
});
