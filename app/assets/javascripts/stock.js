//= require stock_order
//= require opinion
//= require charts/ext
//= require stocks/realtime

//stock show

var StockShow = {
  stock_id: null,
  money_unit: '$',
  stock_previous_close_price: null,
  clicked_period: false,
  kline_datas: {},
  day_datas: {}, //所有的分时数据（按周）
  six_months_datas: {}, //最近6个月分时数据（按天）
  one_day_minutes_datas: {},
  week_minutes_datas: {},
  stock_chart: null,
  show_minutes_time: true, //判断分时图tooltip日期显示格式
  current_chart_datas_name: '1dm',
  update_stock_chart_datas: true,
  start_trade_timestamp: null,
  end_trade_timestamp: null,
  start_trade_timestamp_of_utc: null,
  end_trade_timestamp_of_utc: null,
  six_months_ago_timestamp: null,
  market_area: null,

  init: function(opts){
    this.stock_previous_close_price = opts.stock_previous_close_price;
    this.start_trade_timestamp = opts.start_trade_timestamp;
    this.end_trade_timestamp = opts.end_trade_timestamp;
    this.start_trade_timestamp_of_utc = opts.start_trade_timestamp_of_utc;
    this.end_trade_timestamp_of_utc = opts.end_trade_timestamp_of_utc;
    this.six_months_ago_timestamp = opts.six_months_ago_timestamp;
    this.stock_id = opts.stock_id;
    this.money_unit = opts.money_unit;
    this.market_area = opts.market_area;
    

    StockShow.followHandle();
    StockShow.chartTypeButtonClickHandle();
    StockShow.timePeriodClickHandle();
    StockShow.setMinutesChart();

    $(document).on("mouseleave", "#stock_chart", function(){
      HighStockExt.triggerMinutesLastPoint();
    })

    $('.sortcolumn').columnsortable();
    $('.compare_chart').drawsquare();

    // 组合SmallChart
    BasketMiniChart.init();
    
    // 同步逐笔数据
    StockShow.syncStockRtLogs();

    StockShow.bindNewsClickHandle();
    
    StockShow.bindTradingFlowClickHandle();

    setInterval("StockRealtime.rtHeartbeat();", 120000);
    setInterval("StockMinutePrice.AjaxUpdateMinutes(StockShow.start_trade_timestamp_of_utc,StockShow.end_trade_timestamp_of_utc);", 60000);
  },
  
  syncStockRtLogs: function(){
   if(StockShow.market_area == "cn"){
    $.get("/ajax/stocks/" + StockShow.stock_id + "/rt_logs");
   }
  },
  
  bindNewsClickHandle: function(){
    $('.j_news_tag').on('click', function(){
      // 同步个股新闻
      StockShow.syncStockNews();
      // 同步个股公告
      StockShow.syncStockNotify();
    })
  },

  syncStockNews: function(){
    if(StockShow.market_area == "cn" || StockShow.market_area == "hk"){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/news");
    }
  },

  syncStockNotify: function(){
    if(StockShow.market_area == "cn" || StockShow.market_area == "hk"){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/announcements");
    }
  },
  
  bindTradingFlowClickHandle: function(){
    $('.j_trading_flow_tag').on('click', function(){
      // 同步板块资金流向
      StockShow.syncStockTradingFlows();

      // 同步流入流出百分比
      StockShow.syncTradingFlowPieChart();
    
      // 批量同步板块资金流向
      StockShow.bubbleSyncTradingFlows();
    
      StockShow.syncIndustryTradingFlows();
    })
  },
  
  syncStockTradingFlows: function(){
    if(StockShow.market_area == "cn"){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/trading_flows");
    }
  },

  bubbleSyncTradingFlows: function(){
    if(StockShow.market_area == "cn"){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/bubble_trading_flows");
    }
  },

  syncTradingFlowPieChart: function(){
    if(StockShow.market_area == "cn"){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/flow_charts");
    }
  },

  syncIndustryTradingFlows: function(){
    if(StockShow.market_area == "cn"){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/industry_percent_flows", {}, function(datas){
        StockShow.setIndustryTradingFlowChart('j_industry_percent_flows', datas);
      })
    }
  },

  setIndustryTradingFlowChart: function(chart_id, datas){
    $('#' + chart_id).highcharts({
        global : {
          useUTC: false
        },
        chart: {
          style: {
            fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
            fontSize: '12px'
          }
        },
        title: {
            text: null,
            x: -20 //center
        },
        xAxis: {
          type: 'datetime',
          dateTimeLabelFormats : {
            day: '%m-%d',
            week: '%m-%d',
            month: '%m月',
            year: '%Y年'
          }
        },  
        yAxis: {
          title: {
            text: null 
          },
          labels: {
            format: "{value}%"
          },
          plotLines: [{
              value: 0,
              width: 1,
              color: '#808080'
          }],
          min: 0
        },
        tooltip: {
	        xDateFormat: "%Y-%m-%d",
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
              s += '<br/><span style="line-height: 25px;color:'+ point.series.color +'">' + point.series.name + '：<span style="color:' + point.point.y + '">' + point.point.y.toFixed(2) + ' %</span></span>';
            })
            return s;
          }
        },
        credits: {
          enabled: false
        },
        legend: {
          enabled: false
        },
        plotOptions: {
          line: {
            // lineWidth: 1,
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
          name: '小单',
          data: datas[0],
          color: "#87bdee"
        }, {
          name: '大单',
          data: datas[1],
          color: "#7DCD6D"
        }, {
          name: '超大单',
          data: datas[2],
          color: "#8600FF"
        }, {
          name: '主力',
          data: datas[3],
          color: "#0000E3"
        }]
    });
  },

  setTradingFlowPieChart: function(datas){
  
    Highcharts.getOptions().plotOptions.pie.colors = ['#f05050','#f48484','#f9b9b9','#fcdcdc','#cdedd8','#94d7ac','#71ca90','#4dbd74'],
    $('.stockFoundPieChart').highcharts({
        chart: {
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false
        },
        // title:{text: '实时成交信息',style: {'font-size':'14px'}},
        title:false,
        tooltip:false,
        credits: {
          enabled: false
        },
        plotOptions: {
            pie: {
                enableMouseTracking:false,
                innerSize:"60%",
                // allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                    enabled: false,
                    formatter: function(){
                      if(this.percentage > 0){
                        return '<b>' + this.point.name + '</b>:<br />' + Highcharts.numberFormat(this.percentage, 2) + '%';
                      }
                    },
                    // format: '<b>{point.name}</b>',
                    style: {
                        color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                    }
                }
            }
        },
        series: [{
            type: 'pie',
            name: 'Browser share',
            data: [
                ['超大单流入',  datas[0]],
                ['大单流入',    datas[1]],
                ['中单流入',    datas[2]],
                ['小单流入',    datas[3]],
                ['小单流出',    datas[4]],
                ['中单流出',    datas[5]],
                ['大单流出',    datas[6]],
                ['超大单流出',  datas[7]]
            ]
        }]
    });

  },

  followHandle: function(){
    $(document).on("click", ".follow_or_unfollow.btn_dropDown a, .follow_or_unfollow.btn_add", function(){
      StockShow.followOrUnfollowStock(StockShow.stock_id, this);
    })

    $(document).on('click', '.j_follow_basket', function(){
      StockShow.followBasket(isLogined(), $(this).parents('li').attr('basket-id'), $(this));
      return false;
    })
  },

  followOrUnfollowStock: function(stock_id, obj){
    if (!$(obj).hasClass("loading")){
      $(obj).addClass("loading");
      var prev_div = $(".follow_or_unfollow").prev("div");

      $.post("/ajax/stocks/" + stock_id + "/follow_or_unfollow", {}, function(datas){
        $(".follow_or_unfollow").remove();
        var special_class = _is_index ? "" : "text-gap"; //指数页面关注不需要text-gap

        if (datas.followed){
          prev_div.after('<span class="w_btn addMyFocus btn_dropDown follow_or_unfollow '+special_class+'">已关注<a href="javascript:">取消关注</a></span>');
        }else{
          prev_div.after('<span class="b_btn addMyFocus btn_add follow_or_unfollow '+special_class+'">关注</span>');
        }
      })
    }
  },

  //关注 or 取消关注 主题
  followBasket: function(user_logined, basket_id, obj){
    if (user_logined){
      $.post("/ajax/baskets/" + basket_id + "/follow", {}, function(data){
        var follow_count_obj = $(obj).next().find(".heart").next();
        if (data.followed == true){
          $(obj).parent().removeClass().addClass("themeItem favAdded");
          follow_count_obj.text(parseInt(follow_count_obj.text())+1);
        }else{
          $(obj).parent().removeClass().addClass("themeItem");
          follow_count_obj.text(parseInt(follow_count_obj.text())-1);
        }
      });
    }else{
      CaishuoAlert("请登录！");
    }
  },

  chartTypeButtonClickHandle: function(){
    $("#chart_type_btns li").on("click", function(){
      $(this).addClass("active").siblings().removeClass("active");
    })
  },

  showQuotePricesChartDiv: function(){
    $("#chart_div > div:eq(2)").hide();
    $("#kline_time_period").hide();
    $("#chart_div > div:eq(1)").show();
    $("#time_period").show();
  },

  showKlinesChartDiv: function(kline_type){
    $("#chart_div > div:eq(1)").hide();
    $("#time_period").hide();
    $("#chart_div > div:eq(2)").show();
    $("#kline_time_period").show();
    StockShow.setKlineChart(kline_type);
    StockShow.displayKlineBtns(kline_type);
  },

  displayKlineBtns: function(kline_type){
    $("#kline_time_period li").removeClass("active").hide();
    $(".kl_btn_" + kline_type).show();
    var btn_index = kline_type == "week" ? 3 : 1;
    $(".kl_btn_" + kline_type + ":eq(" + btn_index + ")").addClass("active");
  },

  timePeriodClickHandle: function(){
    $("#time_period li").on("click", function(){
      $(this).addClass("active").siblings().removeClass("active");
      StockShow.clicked_period = true;
      StockShow.setChartExtremes(parseInt($(this).attr("data")), StockShow.end_trade_timestamp + 8*3600*1000);
    })

    $("#kline_time_period li").on("click", function(){
      $(this).addClass("active").siblings().removeClass("active");
      StockShow.clicked_period = true;
      StockShow.setKlineChartExtremes(parseInt($(this).attr("data")), StockShow.end_trade_timestamp + 8*3600*1000);
    })
  },

  setChartExtremes: function(begin_timestamp, end_timestamp){
    var chart = $('#stock_chart').highcharts();
    chart.xAxis[0].setExtremes(begin_timestamp, end_timestamp);
  },

  setKlineChartExtremes: function(begin_timestamp, end_timestamp){
    var chart = $('#kline_chart').highcharts();
    chart.xAxis[0].setExtremes(begin_timestamp, end_timestamp);
  },

  clearChartBtnActive: function(){
    if (!this.clicked_period){
      $("#time_period li").removeClass("active");
      $("#kline_time_period li").removeClass("active");
    }else{
      this.clicked_period = false;
    }
  },

  setKlineChart: function(type){
    var buttons = ChartExt.getKlineButtonsByType(type);
    var tick_interval = type == "day" ? 2592000000 : null;
    $('#kline_chart').html("");
    if (StockShow.kline_datas[type] == undefined){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/klines", {type: type}, function(datas){
        StockShow.kline_datas[type] = ChartExt.getOhlcAndVolumeDatas(datas);
        StockShow.drawKlineChart(type, buttons, tick_interval);
      })
    }else{
      StockShow.drawKlineChart(type, buttons, tick_interval);
    }
  },

  drawKlineChart: function(type, buttons, tick_interval){
    var kline_datas = StockShow.kline_datas[type], 
        interval = ChartExt.getKlineXaixsIntervalByType(type);
    var ohlc_length = kline_datas.ohlc.length, 
        ohlc_first_ts = kline_datas.ohlc[0].x,
        ohlc_last_ts = kline_datas.ohlc[ohlc_length-1].x;
    if (ohlc_last_ts - ohlc_first_ts >= interval){
      var max = null, ordinal = true;
    }else{
      var max = ohlc_first_ts + interval, ordinal = false;
    }
    
    ChartExt.setChartOpions();
    $('#kline_chart').highcharts('StockChart', {
        chart: {
          style: {
            fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
            fontSize: '12px'
          },
          panning: false,
          margin: 0,
          marginTop: 26,
          marginRight: 0,
          marginLeft: 0,
          spacingBottom: 0,
          animation: false,
          borderWidth: 1,
          borderColor: '#F0F0F0',
          events: {
            load: function(){
              ChartExt.addFirstXLabelTo(this, 6, this.xAxis[0].height+15);
            },
            redraw: function(){
              ChartExt.addFirstXLabelTo(this, 6, this.xAxis[0].height+15);
            }
          }
        },
        rangeSelector: {
            enabled: true,
            buttons: buttons,
            selected: 0,
            inputEnabled: false,
            inputDateFormat : "%Y-%m-%d",
            inputStyle: {
              color: '#1f1f1f',
              fontWeight: 'bold'
            },
            labelStyle: {
              color: '#0b1318',
              fontWeight: 'bold'
            }
        },

        plotOptions: {
            candlestick: {
                color: '#4daf7b',
                lineColor: '#4daf7b',
                upLineColor: '#e4462e',
                upColor: '#e4462e',
                turboThreshold: Number.MAX_VALUE,
                dataGrouping: {
                  enabled: false,
                  groupPixelWidth: 10,
                  units: StockShow.klineGroupingUnits
                },
                tooltip: {
                  crosshairs: [true, true]
                }
            },
            column: {
                // color: 'black', 
                turboThreshold: Number.MAX_VALUE,
                dataGrouping: {
                  enabled: false,
                  groupPixelWidth: 10,
                  units: StockShow.klineGroupingUnits
                },
                colorByPoint: true
            },
            line: {
              lineWidth: 1,
              enableMouseTracking: false
            }
        },

        title: {
            text: null
        },

        xAxis: {
          gridLineWidth: 1,
          gridLineColor: '#F0F0F0',
          dateTimeLabelFormats : {
            millisecond: '%H:%M',
            second: '%H:%M',
            minute: '%H:%M',
            day: '%m-%d',
            week: '%m-%d',
            month: '%Y/%m',
            year: '%Y年'
          },
          events: {
            afterSetExtremes: function(e) {
              StockShow.clearChartBtnActive();
            }
          },
          tickInterval: tick_interval,
          // tickPixelInterval: 130,
          top: -5,
          ordinal: ordinal,
          max: max,
          minorGridLineWidth: 0,
          minorTickLength: 0,
          lineWidth: 0,
          tickWidth: 0,
          tickPositioner: function(){
            return ChartExt.calXTicks(this.chart.series[0].xData, this.min, this.max);
          },
          labels: {
            align: 'left',
            x: 6,
            formatter: function () {
              var format = ChartExt.xDateFormatBy(this.axis.min, this.axis.max);
              if (StockShow.end_trade_timestamp >= this.value){
                return Highcharts.dateFormat(format, this.value);
              }
            }
          }
        },

        yAxis: [{
            opposite: false,
            offset: -20,
            title: {
                text: null
            },
            labels: {
              align: 'left'
            },
            height: 200,
            top: 26,
            gridLineColor: '#F0F0F0',
            tickAmount: 4
        }, {
            opposite: false,
            offset: -15,
            title: {
                text: null
            },
            labels: {
              align: 'left',
              formatter: function(){
                return "";
              }
            },
            top: 250,
            height: 60,
            tickPixelInterval: 30,
            gridLineColor: '#F0F0F0',
            gridLineWidth: 0
        }],

        navigator: {
          height: 40,
          xAxis: {
            gridLineWidth: 0
          }
        },
        scrollbar: {
          liveRedraw: false,
          enabled: false
        },
        credits: {
          enabled: false
        },

        tooltip: {
          crosshairs: [true, false],
          followPointer: true,
          positioner: function(boxWidth, boxHeight, point) {
            var chart = this.chart;
            if((point.plotX+boxWidth*2) >= chart.plotWidth){
              return { x: point.plotX - boxWidth - 30, y: 50};
            }
            return { x: point.plotX + 50, y: 50};
          },
          shared: true,
          useHTML: true,
          borderColor:'#dfdfdf',
          backgroundColor: 'rgba(255, 255, 255, 0.85)',
          shadow: false, 
          valueDecimals: 2,
          style: {
            padding: '12px'
          },
          formatter: function() {
            var s = '<b style="line-height: 25px;">' + Highcharts.dateFormat('%Y-%m-%d %A', this.x) + '</b>';
            $.each(this.points, function(i, point) {
              if (point.series.index == 0){
                s += '<br/><span style="line-height: 25px;">开盘价：' + point.point.open.toFixed(2) + "</span>";
                s += '<br/><span style="line-height: 25px;">最高价：' + point.point.high.toFixed(2) + "</span>";
                s += '<br/><span style="line-height: 25px;">最低价：' + point.point.low.toFixed(2) + "</span>";
                s += '<br/><span style="line-height: 25px;">收盘价：' + point.point.close.toFixed(2) + "</span>";
                s += '<br/><span style="line-height: 25px;">涨跌额：' + ChartExt.upOrDownStyle(point.point.change, false) + "</span>";
                s += '<br/><span style="line-height: 25px;">涨跌幅：' + ChartExt.upOrDownStyle(point.point.change_percent, true) + "</span>";
                StockShow.setKlineInfo(Highcharts.dateFormat('%Y-%m-%d', this.x), point.point.open, point.point.high, 
                                       point.point.low, point.point.close, ChartExt.humanizedVolume(point.point.volume), 
                                       point.point.change_percent.toFixed(2) + "%", point.point.ma5, point.point.ma10, 
                                       point.point.ma20, point.point.ma30);
              }else{
                s += '<br/><span style="line-height: 25px;">成交量：' + ChartExt.humanizedVolume(point.y) + "</span>";
              }
            })
            return s;
          },
          xDateFormat: "%Y-%m-%d"
        },
        
        series: [{
            type: 'candlestick',
            name: 'AAPL',
            data: kline_datas.ohlc,
            zIndex: 20
        }, {
          type: 'line',
          name: 'ma5',
          data: kline_datas.ma5,
          yAxis: 0,
          color: '#D2691E'
        }, {
          type: 'line',
          name: 'ma10',
          data: kline_datas.ma10,
          yAxis: 0,
          color: '#6A5ACD'
        }, {
          type: 'line',
          name: 'ma20',
          data: kline_datas.ma20,
          yAxis: 0,
          color: '#4daf7b'
        }, {
          type: 'line',
          name: 'ma30',
          data: kline_datas.ma30,
          yAxis: 0,
          color: '#D02090'
        }, {
            type: 'column',
            name: 'Volume',
            data: kline_datas.volume,
            yAxis: 1
        }]
    }, function(chart){
      setTimeout(function () { $("#kline_chart .highcharts-button").hide(); }, 0);
      StockShow.showKlineInfosDiv();
      HighStockExt.addBorderLinesToKlineChart();
    });
    
    //初始化kline后，kline_info默认显示最后一条
    var last_datas = kline_datas.ohlc[kline_datas.ohlc.length-1];
    StockShow.setKlineInfo(Highcharts.dateFormat('%Y-%m-%d', last_datas.x), last_datas.open, last_datas.high, 
                           last_datas.low, last_datas.close, ChartExt.humanizedVolume(last_datas.volume), 
                           last_datas.change_percent.toFixed(2) + "%", last_datas.ma5, last_datas.ma10, 
                           last_datas.ma20, last_datas.ma30);
  },

  setKlineInfo: function(date, open, high, low, close, change, change_percent, ma5, ma10, ma20, ma30){
    $("#kline_info span:eq(0)").text(date);
    $("#kline_info span:eq(1)").text(open.toFixed(2));
    $("#kline_info span:eq(2)").text(high.toFixed(2));
    $("#kline_info span:eq(3)").text(low.toFixed(2));
    $("#kline_info span:eq(4)").text(close.toFixed(2));
    $("#kline_info span:eq(5)").text(change);
    $("#kline_info span:eq(6)").text(change_percent);
    $("#kline_mainfo span:eq(0)").text(ma5);
    $("#kline_mainfo span:eq(1)").text(ma10);
    $("#kline_mainfo span:eq(2)").text(ma20);
    $("#kline_mainfo span:eq(3)").text(ma30);
  },

  showKlineInfosDiv: function(){
    $("#kline_info").show();
    $("#kline_mainfo").show();
  },

  hideKlineInfosDiv: function(){
    $("#kline_info").hide();
    $("#kline_mainfo").hide();
  },

  //分时图
  setMinutesChart: function(){
    if (StockShow.one_day_minutes_datas.prices == undefined){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/quote_prices", {}, function(datas){
        StockShow.adjustedDayDatas(datas.prices);
        StockShow.adjustedOneDayMinuteDatas(datas.one_day_minutes);
        StockShow.drawMinutesChart(StockShow.one_day_minutes_datas.prices, StockShow.one_day_minutes_datas.volume, StockShow.navigatorDatas());
        HighStockExt.setMinuteChartYaxisMinMax(StockShow.getOneDayMinutesMaxMin());

        HighStockExt.actionsAfterMinuteChartRedrawed();
        StockShow.adjustedWeekMinutesDatas(datas.week_minutes);
        StockShow.adjustedSixMonthsDatas(datas.six_months);
      })
    }else{
      $("#time_period li:first").trigger("click");
    }
  },

  //只更新chart的数据
  updateChartSeriesData: function(start_timestamp, end_timestamp){
    var selected_datas = StockShow.selectStockChartDatas(start_timestamp+10, end_timestamp);
    if (StockShow.update_stock_chart_datas == true){
      var chart = $('#stock_chart').highcharts();
      chart.series[0].setData(selected_datas.prices, false);
      chart.series[1].setData(selected_datas.volume, false);
      chart.redraw();
    }
    HighStockExt.actionsAfterMinuteChartRedrawed();
  },

  selectStockChartDatas: function(start_timestamp, end_timestamp){
    var datas = {};
    var min, max, minmax_attrs = {min: null, max: null};
    StockShow.update_stock_chart_datas = true;
    StockShow.show_minutes_time = false;
    if(start_timestamp >= parseInt($("#time_period li:eq(0)").attr("data"))){
      datas = StockShow.one_day_minutes_datas;
      StockShow.show_minutes_time = true;
      StockShow.current_chart_datas_name = '1dm';
      minmax_attrs = StockShow.getOneDayMinutesMaxMin();
      HighStockExt.minute_chart_compare_value = StockShow.stock_previous_close_price;
    }else if(start_timestamp >= parseInt($("#time_period li:eq(1)").attr("data"))){
      datas = StockShow.week_minutes_datas;
      StockShow.show_minutes_time = true;
      StockShow.current_chart_datas_name = '5dm';
      HighStockExt.minute_chart_compare_value = datas.prices[0] ? datas.prices[0].y : 0;
    }else if(start_timestamp >= StockShow.six_months_ago_timestamp){
      datas = StockShow.six_months_datas;
      StockShow.update_stock_chart_datas = StockShow.current_chart_datas_name == 'day-6m' ? false : true;
      StockShow.current_chart_datas_name = 'day-6m';
      HighStockExt.minute_chart_compare_value = StockShow.firstValueByStartTimestamp(datas.prices, start_timestamp);
    }else{
      datas = StockShow.day_datas;
      StockShow.update_stock_chart_datas = StockShow.current_chart_datas_name == 'day' ? false : true;
      StockShow.current_chart_datas_name = 'day';
      var first_value = StockShow.firstValueByStartTimestamp(datas.prices, start_timestamp);
      if (first_value != null){
        HighStockExt.minute_chart_compare_value = first_value;
      }
    }
    HighStockExt.setMinuteChartYaxisMinMax(minmax_attrs);
    return datas;
  },

  firstValueByStartTimestamp: function(datas, timestamp){
    var prices = [];
    //timestamp多了10微秒
    for(index in datas){
      if (datas[index].x>=timestamp-10){
        return datas[index].y;
        break;
      }
    }
  },

  navigatorDatas: function(){
    var today_point = StockShow.one_day_minutes_datas.prices[0],
        y_value = today_point ? today_point.y : null, 
        appended_points = [{x:StockShow.end_trade_timestamp, y: y_value}];
    return StockShow.day_datas.prices.concat(appended_points);
  },

  adjustedDayDatas: function(datas){
    var day_datas = StockShow.getPricesAndVolumeDatas(datas);
    StockShow.day_datas.prices = day_datas.prices;
    StockShow.day_datas.volume = day_datas.volume;
  },

  adjustedSixMonthsDatas: function(datas){
    StockShow.six_months_datas = StockShow.getPricesAndVolumeDatas(datas);
  },

  adjustedOneDayMinuteDatas: function(datas){
    var one_day_minutes_datas = StockShow.getPricesAndVolumeDatas(datas);
    var end_ts = one_day_minutes_datas.prices.length>0 ? one_day_minutes_datas.prices.slice(-1)[0].x : StockShow.end_trade_timestamp;
    var appended_points = StockShow.minuteDatasAppendedPoints(end_ts, 60000);
    StockShow.one_day_minutes_datas.prices = this.exceptDatasAfterEndTime(one_day_minutes_datas.prices).concat(appended_points);
    StockShow.one_day_minutes_datas.volume = this.exceptDatasAfterEndTime(one_day_minutes_datas.volume).concat(appended_points);
  },

  exceptDatasAfterEndTime: function(datas){
    var new_datas = [];
    $.each(datas, function(index){
      if (datas[index].x <= StockShow.end_trade_timestamp){
        new_datas.push(datas[index]);
      }
    })
    return new_datas;
  },

  minuteDatasAppendedPoints: function(exist_end_ts, interval){
    return ChartExt.minuteDatasAppendedPoints(StockShow.market_area, StockShow.end_trade_timestamp, exist_end_ts, interval);
  },

  getOneDayMinutesMaxMin: function(){
    var max, min;
    var prices = [StockShow.stock_previous_close_price];
    $.each(StockShow.one_day_minutes_datas.prices, function(index){
      var price = StockShow.one_day_minutes_datas.prices[index].y;
      if (price != null) prices.push(price);
    })
    $.each(prices, function(index){
      if (max == undefined || max < prices[index]) max = prices[index];
      if (min == undefined || min > prices[index]) min = prices[index];
    })
    return {min: min, max: max};
  },

  adjustedWeekMinutesDatas: function(datas){
    var week_minutes_datas = StockShow.getPricesAndVolumeDatas(datas),
        end_ts = week_minutes_datas.prices.length>0 ? week_minutes_datas.prices.slice(-1)[0].x : StockShow.end_trade_timestamp,
        appended_points = StockShow.minuteDatasAppendedPoints(end_ts, 600000);
    StockShow.week_minutes_datas.prices = this.exceptDatasAfterEndTime(week_minutes_datas.prices).concat(appended_points);
    StockShow.week_minutes_datas.volume = this.exceptDatasAfterEndTime(week_minutes_datas.volume).concat(appended_points);
  },

  getPricesAndVolumeDatas: function(ori_datas){
    var prices = [], color, 
      volume = [], compare_now, compare_pre,
      dataLength = ori_datas.length;
      
    for (i = 0; i < dataLength; i++) {
      prices.push({x: ori_datas[i][0], y: ori_datas[i][1]});
      compare_now = ori_datas[i][1];
      compare_pre = i==0 ? StockShow.stock_previous_close_price : ori_datas[i-1][1] ;
      color = compare_now<=compare_pre ? '#4daf7b' : '#e4462e';
      volume.push({x: ori_datas[i][0], y: ori_datas[i][2], color: color});
    }
    return {'prices': prices, 'volume': volume}
  },

  drawMinutesChart: function(prices_datas, volume_datas, navigator_datas){
    ChartExt.setChartOpions();
    $('#stock_chart').highcharts('StockChart', {
        chart: {
          margin: 0,
          marginTop: 26,
          marginRight: 0,
          marginLeft: 0,
          spacingBottom: 0,
          style: {
            fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
            fontSize: '12px'
          },
          animation: false,
          panning: false,
          borderWidth: 1,
          borderColor: '#F0F0F0',
          events: {
            load: function(){
              if (StockShow.isCnDayMinutes()){
                ChartExt.adjustOneDayMinutesLabels(720);
              }
            },
            redraw: function(){
              $(".highcharts-cs-x-first-label").remove();
              if (!StockShow.isMinutes()){
                ChartExt.addFirstXLabelTo(this, 6, 240);
              }else if(StockShow.isWeekMinutes()){
                ChartExt.addFirstXLabelTo(this, 60, 240);
              }else if(StockShow.isCnDayMinutes()){
                ChartExt.adjustOneDayMinutesLabels(720);
              }
            }
          }
        },
        rangeSelector: {
            enabled: false,
            inputEnabled: true,
            inputDateFormat : "%Y-%m-%d",
            buttons: [],
            inputStyle: {
              color: '#1f1f1f',
              fontWeight: 'bold'
            },
            labelStyle: {
              color: '#0b1318',
              fontWeight: 'bold'
            }
        },

        plotOptions: {
            line: {
              turboThreshold: Number.MAX_VALUE,
              dataGrouping: {
                enabled: false
              },
              connectNulls: true,
              color: "#4183c4",
              threshold: null,
              lineWidth: 1.2,
              states: {
                hover: {
                  lineWidth: 1.2
                }
              }
            },
            area: {
              turboThreshold: Number.MAX_VALUE,
              dataGrouping: {
                enabled: false
              },
              connectNulls: true,
              fillColor : {
                linearGradient : {
                  x1: 0, 
                  y1: 0, 
                  x2: 0, 
                  y2: 1
                },
                stops : [[0, "rgba(135, 189, 238, 1)"], [1, "rgba(135, 189, 238, 0)"]]
              },
              color: "#87bdee",
              threshold: null
            },
            column: {
              color: '#d0d0d0', 
              turboThreshold: Number.MAX_VALUE,
              dataGrouping: {
                enabled: false
              }
            },
            series: {
                point: {
                    events: {
                        mouseOver: function(){
                          HighStockExt.pointMouseOverAction(this);
                        },
                        mouseOut: function () {
                          HighStockExt.pointMouseOutAction(this);
                        }
                    }
                }
            }
        },

        title: {
            text: null
        },

        xAxis: {
          type: 'datetime',
          offset: -67,
          lineWidth: 0,
          gridLineWidth: 1,
          gridLineColor: '#F0F0F0',
          minorGridLineWidth: 0,
          tickWidth: 0,
          dateTimeLabelFormats : {
            millisecond: '%H:%M',
            second: '%H:%M',
            minute: '%H:%M',
            day: '%m-%d',
            week: '%m-%d',
            month: '%Y/%m',
            year: '%Y年'
          },
          events: {
            afterSetExtremes: function(e) {
              StockShow.clearChartBtnActive();
              StockShow.updateChartSeriesData(e.min, e.max);
              StockShow.setChartAttrs(e.min, e.max);
            },
            setExtremes: function(e){
              // StockShow.setStockChartMinmax(null, null);
            }
          },
          minRange: 6*3600*1000,
          minTickInterval: 3600*1000,
          showLastLabel: true,
          tickPositioner: function(){
            if (StockShow.isCnDayMinutes()){
              var ticks = [], end_ts = StockShow.end_trade_timestamp, hours = [5.5, 4.5, 3.5, 1, 0];
              $.each(hours, function(i){
                ticks.push(end_ts - hours[i]*3600000);
              })
              return ticks;
            }else if(StockShow.needHandedCalTicks()){
              return ChartExt.calXTicks(this.chart.series[0].xData, this.min, this.max);
            }
          },
          labels: {
            x: 6,
            formatter: function () {
              if (StockShow.isCnDayMinutes()){
                if (this.value == (StockShow.end_trade_timestamp - 3.5*3600000)){
                  return '11:30/13:00';
                }else{
                  return Highcharts.dateFormat("%H:%M", this.value);
                }
              }else if(StockShow.isHkDayMinutes()){
                if (this.value == (StockShow.end_trade_timestamp - 3*3600000)){
                  return '12:00/13:00';
                }else{
                  return Highcharts.dateFormat("%H:%M", this.value);
                }
              }else{
                var format = ChartExt.xDateFormatBy(this.axis.min, this.axis.max);
                if (StockShow.end_trade_timestamp >= this.value){
                  return Highcharts.dateFormat(format, this.value);
                }
              }
            }
          }
        },

        yAxis: [{
            opposite: false,
            offset: -15,
            title: {
                text: null
            },
            labels: {
              align: 'left',
              formatter: function () {
                return "";
              }
            },
            height: 200,
            gridLineColor: '#F0F0F0',
            tickPixelInterval: 40,
            tickPositioner: function(){
              if (this.dataMin != null && this.dataMax != null){
                // if (this.dataMin == this.dataMax && this.dataMax == HighStockExt.minute_chart_compare_value) return [AccMath.sub(HighStockExt.minute_chart_compare_value,0.1), HighStockExt.minute_chart_compare_value, AccMath.add(HighStockExt.minute_chart_compare_value,0.1)];
                return ChartExt.calYTickPositions(HighStockExt.minute_chart_compare_value, this.dataMin, this.dataMax);
              }
            }
        }, {
            opposite: false,
            offset: -15,
            title: {
                text: null
            },
            labels: {
              align: 'left',
              formatter: function () {
                return "";
              }
            },
            top: 250,
            height: 60,
            gridLineColor: '#FFF',
            tickPixelInterval: 30
        }],

        credits: {
          enabled: false
        },

        navigator: {
          series: {
            data: navigator_datas
          },
          adaptToUpdatedData: false,
          height: 40,
          xAxis: {
            gridLineWidth: 0
          }
        },
        scrollbar: {
          liveRedraw: false,
          enabled: false
        },

        tooltip: {
          crosshairs: [false],
          positioner: function(boxWidth, boxHeight, point) {
            return {x: 50, y: -8};
          },
          shared: true,
          useHTML: true,
          shadow: false,
          borderColor:'rgba(255, 255, 255, 0)',
          backgroundColor: 'rgba(255, 255, 255, 0)',
          valueDecimals: 2,
          style: {
            // padding: '12px'
          },
          formatter: function() {
            HighStockExt.minutesChartTooltips(this.points, this);
          }
        },
        
        series: [{
            type: 'line',
            name: 'minutes',
            enabledCrosshairs: true,
            data: prices_datas
        }, {
            type: 'column',
            name: 'Volume',
            data: volume_datas,
            yAxis: 1
        }]
    }, function(chart){
      setTimeout(function () { $("#stock_chart .highcharts-button").hide(); }, 0);
      HighStockExt.triggerMinutesLastPoint();
      HighStockExt.addBorderLinesToMinutesChart();
    });
  },

  setChartAttrs: function(min, max){
    var chart = $('#stock_chart').highcharts();
    var ts_interval = max - min;
    var tick_interval, show_last_label = true, label_x = 6, align = 'left';
    if (ts_interval > 864000000){
      
    }else if(ts_interval > 86400000){
      tick_interval = 86400000;
      // show_last_label = false;
      label_x = 55;
    }else{
      tick_interval = 3600000;
      align = 'center';
    }
    chart.xAxis[0].update({minTickInterval: tick_interval, showLastLabel: show_last_label, labels: {x: label_x, align: align}});
  },

  isCnDayMinutes: function(){
    return StockShow.current_chart_datas_name == '1dm' && StockShow.market_area == 'cn';
  },

  isHkDayMinutes: function(){
    return StockShow.current_chart_datas_name == '1dm' && StockShow.market_area == 'hk';
  },

  needHandedCalTicks: function(){
    return !((StockShow.current_chart_datas_name == '1dm' && StockShow.market_area != 'cn') ||
      StockShow.current_chart_datas_name == '5dm')
  },

  isMinutes: function(){
    return ['1dm', '5dm'].indexOf(this.current_chart_datas_name) >= 0;
  },

  isWeekMinutes: function(){
    return this.current_chart_datas_name == '5dm';
  }

}

//分时数据推送更新分时数据源
var StockMinutePrice = {
  //ajax
  AjaxUpdateMinutes: function(start_trade_timestamp, end_trade_timestamp){
    var now_timestamp = (new Date()).getTime();
    //由于数据延迟15分钟，所以加上20分钟
    if (now_timestamp >= start_trade_timestamp && now_timestamp <= end_trade_timestamp+1200000){
      this.updateMinutesChart();
      HighStockExt.triggerMinutesLastPoint();
    }

    // 当天时间戳大于交易结束时间戳时，表明打开是昨天交易结束前打开的页面，现在已进入
    if (StockShow.end_trade_timestamp_of_utc+12*3600000 < now_timestamp) window.location.reload();
  },

  updateMinutesChart: function(){
    $.get("/ajax/stocks/"+StockShow.stock_id+"/minutes", {}, function(datas){
      StockShow.adjustedOneDayMinuteDatas(datas.one_day_minutes);
      // StockShow.adjustedWeekMinutesDatas(datas.week_minutes);
      if (["今日"].indexOf($("#time_period .active").text()) >= 0){
        $("#time_period .active").trigger("click");
      }
    })
  },

  //push
  update: function(minute_data){
    var timestamp = minute_data.timestamp;
    var price = minute_data.price;
    var volume = minute_data.volume;
    StockMinutePrice.appendToMinutesPrices({x: timestamp, y: price});
    StockMinutePrice.appendToMinutesVolume({x: timestamp, y: volume});
    if (["今日", "5日"].indexOf($("#time_period .active").text()) >= 0){
      $("#time_period .active").trigger("click");
    }
  },

  appendToMinutesPrices: function(data){
    StockShow.one_day_minutes_datas.prices = StockMinutePrice.mergeDatas(StockShow.one_day_minutes_datas.prices, data);
    StockShow.week_minutes_datas.prices = StockMinutePrice.mergeDatas(StockShow.week_minutes_datas.prices, data);
  },

  appendToMinutesVolume: function(data){
    StockShow.one_day_minutes_datas.volume = StockMinutePrice.mergeDatas(StockShow.one_day_minutes_datas.volume, data);
    StockShow.week_minutes_datas.volume = StockMinutePrice.mergeDatas(StockShow.week_minutes_datas.volume, data);
  },

  mergeDatas: function(datas, data){
    if (!StockMinutePrice.checkDataIsPresent(datas, data)){
      datas.push(data);
      return datas.sort(function(a,b){ return a.x-b.x });
    }else{
      return datas;
    }
  },

  checkDataIsPresent: function(datas, data){
    $.each(datas, function(){
      if ($(this).x == data.x){
        return true;
      }
    })
    return false;
  }
}


var HighStockExt = {
  minute_chart: undefined,
  minute_chart_compare_value: null,
  minute_round_digit: 2,

  getMinuteChart: function(){
    if (HighStockExt.minute_chart == undefined){
      HighStockExt.minute_chart = $('#stock_chart').highcharts();
    }
    return HighStockExt.minute_chart;
  },

  actionsAfterMinuteChartRedrawed: function(){
    this.drawPreviousClosePriceLine();
    ChartExt.drawMinuteChartPercentYaxis(this.getMinuteChart(), this.minute_chart_compare_value, HighStockExt.minute_round_digit);
  },

  pointMouseOverAction: function(point){
    var opts = {bottom_y: 256, show_minutes_time: StockShow.show_minutes_time, 
      compare_value: this.minute_chart_compare_value, minute_round_digit: HighStockExt.minute_round_digit};
    ChartExt.pointMouseOverCrossHairs(point, opts);
  },

  pointMouseOutAction: function(point){
    ChartExt.pointMouseOutAction();
  },

  drawPreviousClosePriceLine: function(){
    if (StockShow.current_chart_datas_name == '1dm'){
      var chart = $('#stock_chart').highcharts();
      ChartExt.addLineByYValue(chart, StockShow.stock_previous_close_price);
    }
  },

  setMinuteChartYaxisMinMax: function(minmax){
    //minmax = {min: 1, max:2}
    this.getMinuteChart().yAxis[0].update(minmax);
  },

  valueChangePercent: function(value){
    return ChartExt.valueChangePercent(value, HighStockExt.minute_chart_compare_value, HighStockExt.minute_round_digit);
  },

  minutesChartTooltips: function(points, position){
    var s = ChartExt.minutesChartTooltipTemplate(), 
        format = StockShow.show_minutes_time ? '%Y-%m-%d %H:%M' : '%Y-%m-%d',
        current_price, percent_color, operator, percent, volume, datetime;

    $.each(points, function(i, point) {
      if (point.series.index == 0){
        var percent = HighStockExt.valueChangePercent(point.y);
        s = s.replace(/%current_price%/, point.y.round(HighStockExt.minute_round_digit))
             .replace(/%percent_color%/, percent == 0 ? "gray" : (percent>0 ? "#e4462e" : "#4daf7b"))
             .replace(/%operator%/, percent > 0 ? "+" : "")
             .replace(/%percent%/, percent.toFixed(2));
      }else{
        s = s.replace(/%volume%/, ChartExt.humanizedVolume(point.y));
      }
    })
    s = s.replace(/%datetime%/, Highcharts.dateFormat(format, position.x));
    $("#minutes_chart_info").html(s);
  },

  triggerMinutesLastPoint: function(){
    var price_points = this.getMinuteChart().series[0].points,
        price_point = price_points[price_points.length-1],
        volume_point = this.lastVolumePoint();
    try{
      HighStockExt.minutesChartTooltips([price_point, volume_point], price_point);
    }catch(e){ }
  },

  lastVolumePoint: function(){
    var volume_points = this.getMinuteChart().series[1].points,
        volume_point;
    $.each(volume_points,function(i){
      if (volume_points[i].y != null) volume_point=volume_points[i];
    })
    return volume_point;
  },

  //分时图添加边线
  addBorderLinesToMinutesChart: function(){
    var chart = this.getMinuteChart(), top = chart.plotTop,
        y = top + 223, group_name = 'cs-minutes-chart-borders';
    ChartExt.addHorizonLineBy(chart, y, group_name);
  },

  addBorderLinesToKlineChart: function(){
    var chart = $("#kline_chart").highcharts(),
        y = 250, group_name = 'cs-klines-chart-borders';
    ChartExt.addHorizonLineBy(chart, y, group_name);
  }
}



// Stock，StockShow中方法会逐渐拆分移动到此

var Stock = {
  init: function(){
    if(trade_param != ""){
      Stock.toggleTrade();
    }

    Stock.pageHandler();
  },

  toggleTrade: function(btn){
    $('#trade_div').toggle();
    if ($(btn).attr("loaded") != "true"){
      $(btn).attr("loaded", "true");
      Stock.loadTradeContent(gon.account_id);
    }
  },

  loadTradeContent: function(account_id){
    var params = account_id ? {account_id: account_id} : {};
    $.get("/stocks/"+gon.stock_id+"/trade", params, function(){
      Order.init();
      $('#trade_div').show();
      Stock.changeTradeType();
    })
  },

  changeTradeType: function(){
    if (trade_param == "sell"){
      $("#buy_sell_options input:last").trigger("click");
      Order.sellStock($("#buy_sell_options input:last"));
    }
  },
  
  //
  pageHandler: function(){
    $('.compare_title .asSwitchBtn li').click(function(){
      var target = $(this).attr('data-target');
      $(this).addClass('active').siblings().removeClass();
      $('.'+target).addClass('fixtop').fadeIn(function(){
        $(this).removeClass('fixtop');
      });

      $('.'+$(this).siblings().attr('data-target')).fadeOut();
    });

    $('#StockInfoSwitch .asSwitchBtn li').click(function(){
      $(this).addClass('active').siblings().removeClass();
      $('#StockBasicInfo').toggle($(this).index()==0 && $(this).hasClass('active'));
      $('#StockTradeInfo').toggle($(this).index()==1 && $(this).hasClass('active'));
    });

    $(".tabSwitch").tabso({cntSelect:".MultiTabDisplayArea",tabEvent:"click"});
    
    $('*[data-click-tip], *[data-hover-tip]').ClickHoverTip($('#BubbleBox'));
  }
};



//指标对比
(function($){
  $.fn.drawsquare = function() {
    return $(this).each(function() {
      $(this).find('div.chart').each(function(){
        var $left = $(this).children().eq(0),$right = $(this).children().eq(1);
        var leftval = parseFloat($left.attr('data-value')),rightval = parseFloat($right.attr('data-value'));
        var tmp = leftval * rightval;
        if (tmp>0 || tmp<0){
          var lh = Math.abs(leftval) / (Math.abs(leftval) + Math.abs(rightval));
          $left.height(lh*100 +'%');
          $right.height((1-lh)*100 + '%');
          if (leftval <0){$right.css('top',0);$left.addClass('upsidedown');}
          if (rightval <0){$left.css('top',0);$right.addClass('upsidedown');}
          return;
        }
        if (leftval==0) {$left.height('10%');}
        if (rightval==0) {$right.height('10%');}
        if (isNaN(leftval) && isNaN(rightval)){
          return;
        }else if(isNaN(leftval) && rightval!=0){
          $left.height('0');
          $right.height('100%');
          if (rightval<0) {$left.css('top',0);$right.addClass('upsidedown');}
        }else if(isNaN(rightval) && leftval!=0){
          $left.height('100%');
          $right.height('0');
          if (leftval<0) {$right.css('top',0);$left.addClass('upsidedown');}
        }
      });
    });
  };
})(jQuery);

function gotoCompare(id) {
  $('.tabSwitch a[data-target="compare_stock"]').trigger('click');
  $('#' + id).trigger('click');
}

