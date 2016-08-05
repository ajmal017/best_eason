//= require charts/ext

$(function(){
  HighChartExt.hackPointerRunPointActions();
  ChartExt.setChartOpions();

  $(".stockIndex .stockStatus li").on("click", function(){
    $(this).parent().find("a").removeClass("active");
    $(this).find("a").addClass("active");
    $("#market_index_minute_chart").html("");
    $("#market_index_kline_chart").html("");
    loadMarketIndex();
    OneDayMinute.loadByTab();
  })

  setInterval("OneDayMinute.loadByTab();", 30000);

  $(document).on("mouseleave", "#market_index_minute_chart", function(){
    HighStockExt.triggerMinutesLastPoint();
  })
})

function loadMarketIndex(){
  MarketIndexChart.showQuotePricesChart($("#chart_type_btns li:eq(0)"));
}

var MarketIndexChart = {
  current_market_index_stock_id: null,
  end_trade_timestamp: null,
  exchange_symbol: null,
  previous_close: null,
  minutes_datas: {},
  kline_datas: {},
  update_stock_chart_datas: true,
  show_minutes_time: true,
  current_chart_datas_name: '1dm',

  showQuotePricesChart: function(obj){
    this.activeChartButton(obj);
    $("#market_index_minute_chart").parent().show();
    $("#market_index_kline_chart").parent().hide();
    this.getActiveMarketStockId();
    this.setQuotePriceChart(this.current_market_index_stock_id);
  },

  showKlinesChart: function(kline_type, obj){
    this.activeChartButton(obj);
    $("#market_index_kline_chart").parent().show();
    $("#market_index_minute_chart").parent().hide();
    this.getActiveMarketStockId();
    this.setKlineChart(kline_type, this.current_market_index_stock_id);
  },

  activeChartButton: function(obj){
    $(obj).addClass("active").siblings().removeClass("active");
  },

  getActiveMarketStockId: function(){
    var active_obj = $(".stockIndex .stockStatus a").filter(function(){return $(this).hasClass("active")}).first().parent();
    this.current_market_index_stock_id = active_obj.attr("data-id");
    this.end_trade_timestamp = parseInt(active_obj.attr("data-end-timestamps"));
    this.exchange_symbol = active_obj.attr("data-market-symbol");
    this.previous_close = parseFloat(active_obj.attr("data-previous-close"));
    HighStockExt.minute_chart_compare_value = this.previous_close;
  },

  setQuotePriceChart: function(index_stock_id){
    var market_minutes_datas = MarketIndexChart.minutes_datas[index_stock_id];
    if (market_minutes_datas == undefined){
      $.get("/ajax/stocks/" + index_stock_id + "/quote_prices", {}, function(datas){
        market_minutes_datas = market_minutes_datas || {};
        market_minutes_datas["all"] = MarketIndexChart.adjustedDayDatas(datas.prices);
        market_minutes_datas["one_day"] = MarketIndexChart.adjustedOneDayMinuteDatas(datas.one_day_minutes);
        MarketIndexChart.minutes_datas[index_stock_id] = market_minutes_datas;
        MarketIndexChart.drawQuotePriceChart(market_minutes_datas["one_day"].prices, market_minutes_datas["one_day"].volume, market_minutes_datas["all"].prices);
        HighStockExt.setMinuteChartYaxisMinMax(MarketIndexChart.getOneDayMinutesMaxMin(index_stock_id));

        HighStockExt.actionsAfterMinuteChartRedrawed();
        market_minutes_datas["week"] = MarketIndexChart.adjustedWeekMinutesDatas(datas.week_minutes);
        market_minutes_datas["six_months"] = MarketIndexChart.adjustedSixMonthsDatas(datas.six_months);
        MarketIndexChart.minutes_datas[index_stock_id] = market_minutes_datas;
      })
    }else{
      MarketIndexChart.drawQuotePriceChart(market_minutes_datas["one_day"].prices, market_minutes_datas["one_day"].volume, market_minutes_datas["all"].prices);
      HighStockExt.setMinuteChartYaxisMinMax(MarketIndexChart.getOneDayMinutesMaxMin(index_stock_id));
      HighStockExt.actionsAfterMinuteChartRedrawed();
    }
  },

  //只更新chart的数据
  updateChartSeriesData: function(start_timestamp, end_timestamp){
    var selected_datas = MarketIndexChart.selectStockChartDatas(start_timestamp+10, end_timestamp);
    if (MarketIndexChart.update_stock_chart_datas == true){
      var chart = $('#market_index_minute_chart').highcharts();
      chart.series[0].setData(selected_datas.prices, false);
      chart.series[1].setData(selected_datas.volume, false);
      chart.redraw();
    }
    HighStockExt.actionsAfterMinuteChartRedrawed();
  },

  selectStockChartDatas: function(start_timestamp, end_timestamp){
    var datas = {}, 
        index_stock_id = MarketIndexChart.current_market_index_stock_id, 
        minutes_datas = MarketIndexChart.minutes_datas[index_stock_id];
    var min, max, minmax_attrs = {min: null, max: null};
    MarketIndexChart.update_stock_chart_datas = true;
    MarketIndexChart.show_minutes_time = false;
    if(start_timestamp >= parseInt($("#time_period li:eq(0)").attr("data"))){
      datas = minutes_datas["one_day"];
      MarketIndexChart.show_minutes_time = true;
      MarketIndexChart.current_chart_datas_name = '1dm';
      minmax_attrs = MarketIndexChart.getOneDayMinutesMaxMin(index_stock_id);
      HighStockExt.minute_chart_compare_value = MarketIndexChart.previous_close;
    }else if(start_timestamp >= minutes_datas["week"].prices[0].x){
      datas = minutes_datas["week"];
      MarketIndexChart.show_minutes_time = true;
      MarketIndexChart.current_chart_datas_name = '5dm';
      HighStockExt.minute_chart_compare_value = datas.prices[0].y;
    }else if(start_timestamp >= minutes_datas["six_months"].prices[0].x){
      datas = minutes_datas["six_months"];
      MarketIndexChart.update_stock_chart_datas = MarketIndexChart.current_chart_datas_name == 'day-6m' ? false : true;
      MarketIndexChart.current_chart_datas_name = 'day-6m';
      HighStockExt.minute_chart_compare_value = MarketIndexChart.firstValueByStartTimestamp(datas.prices, start_timestamp);
    }else{
      datas = minutes_datas["all"];
      MarketIndexChart.update_stock_chart_datas = MarketIndexChart.current_chart_datas_name == 'day' ? false : true;
      MarketIndexChart.current_chart_datas_name = 'day';
      var first_value = MarketIndexChart.firstValueByStartTimestamp(datas.prices, start_timestamp);
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

  adjustedDayDatas: function(datas){
    var day_datas = MarketIndexChart.getPricesAndVolumeDatas(datas);
    var appended_points = [{x:MarketIndexChart.end_trade_timestamp + 28800000, y: null}];
    return {prices: day_datas.prices.concat(appended_points), volume: day_datas.volume.concat(appended_points)}
  },

  adjustedSixMonthsDatas: function(datas){
    return MarketIndexChart.getPricesAndVolumeDatas(datas);
  },

  adjustedOneDayMinuteDatas: function(datas){
    var one_day_minutes_datas = MarketIndexChart.getPricesAndVolumeDatas(datas);
    var end_ts = one_day_minutes_datas.prices.length>0 ? one_day_minutes_datas.prices.slice(-1)[0].x : MarketIndexChart.end_trade_timestamp;
    var appended_points = MarketIndexChart.minuteDatasAppendedPoints(end_ts);
    return {prices: this.exceptDatasAfterEndTime(one_day_minutes_datas.prices).concat(appended_points), 
            volume: this.exceptDatasAfterEndTime(one_day_minutes_datas.volume).concat(appended_points)};
  },

  exceptDatasAfterEndTime: function(datas){
    var new_datas = [];
    $.each(datas, function(index){
      if (datas[index].x <= MarketIndexChart.end_trade_timestamp){
        new_datas.push(datas[index]);
      }
    })
    return new_datas;
  },

  minuteDatasAppendedPoints: function(exist_end_ts){
    return ChartExt.minuteDatasAppendedPoints(this.market(), MarketIndexChart.end_trade_timestamp, exist_end_ts, 60000)
  },

  getOneDayMinutesMaxMin: function(index_stock_id){
    var max, min;
    var prices = [MarketIndexChart.previous_close];
    var prices = [];
    $.each(MarketIndexChart.minutes_datas[index_stock_id]["one_day"].prices, function(index){
      var price = MarketIndexChart.minutes_datas[index_stock_id]["one_day"].prices[index].y;
      if (price != null) prices.push(price);
    })
    $.each(prices, function(index){
      if (max == undefined || max < prices[index]) max = prices[index];
      if (min == undefined || min > prices[index]) min = prices[index];
    })
    return {min: min, max: max};
  },

  adjustedWeekMinutesDatas: function(datas){
    return MarketIndexChart.getPricesAndVolumeDatas(datas);
  },

  getPricesAndVolumeDatas: function(ori_datas){
    var prices = [], color, 
      volume = [], compare_now, compare_pre,
      dataLength = ori_datas.length;
      
    for (i = 0; i < dataLength; i++) {
      prices.push({x: ori_datas[i][0], y: ori_datas[i][1]});
      compare_now = ori_datas[i][1];
      compare_pre = i==0 ? this.stock_previous_close_price : ori_datas[i-1][1] ;
      color = compare_now<=compare_pre ? '#4daf7b' : '#e4462e';
      volume.push({x: ori_datas[i][0], y: ori_datas[i][2], color: color});
    }
    return {'prices': prices, 'volume': volume}
  },


  drawQuotePriceChart: function(prices_datas, volume_datas, navigator_datas){
    $('#market_index_minute_chart').highcharts('StockChart', {
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
              if (MarketIndexChart.isCnDayMinutes()){
                ChartExt.adjustOneDayMinutesLabels(688);
              }
            },
            redraw: function(){
              $(".highcharts-cs-x-first-label").remove();
              if (!MarketIndexChart.isMinutes()){
                ChartExt.addFirstXLabelTo(this, 6, 240);
              }else if(MarketIndexChart.isWeekMinutes()){
                ChartExt.addFirstXLabelTo(this, 60, 240);
              }else if(MarketIndexChart.isCnDayMinutes()){
                ChartExt.adjustOneDayMinutesLabels(688);
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
              },
              animation: false
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
          offset: -75,
          lineWidth: 0,
          gridLineWidth: 1,
          gridLineColor: '#F0F0F0',
          dateTimeLabelFormats : {
            millisecond: '%H:%M',
            second: '%H:%M',
            minute: '%H:%M',
            day: '%m.%d',
            week: '%m.%d',
            month: '%Y/%m',
            year: '%Y年'
          },
          events: {
            afterSetExtremes: function(e) {
              MarketIndexChart.updateChartSeriesData(e.min, e.max);
              MarketIndexChart.setChartAttrs(e.min, e.max);
            },
            setExtremes: function(e){
              // MarketIndexChart.setStockChartMinmax(null, null);
            }
          },
          minRange: 6*3600*1000,
          minTickInterval: 3600*1000,
          tickWidth: 0,
          showLastLabel: true,
          tickPositioner: function(){
            if (MarketIndexChart.isCnDayMinutes()){
              var ticks = [], end_ts = MarketIndexChart.end_trade_timestamp, hours = [5.5, 4.5, 3.5, 1, 0];
              $.each(hours, function(i){
                ticks.push(end_ts - hours[i]*3600000);
              })
              return ticks;
            }else if(MarketIndexChart.needHandedCalTicks()){
              return ChartExt.calXTicks(this.chart.series[0].xData, this.min, this.max);
            }
          },
          labels: {
            x: 6,
            formatter: function () {
              if (MarketIndexChart.isCnDayMinutes()){
                if (this.value == (MarketIndexChart.end_trade_timestamp - 3.5*3600000)){
                  return '11:30/13:00';
                }else{
                  return Highcharts.dateFormat("%H:%M", this.value);
                }
              }else if(MarketIndexChart.isHkDayMinutes()){
                if (this.value == (MarketIndexChart.end_trade_timestamp - 3*3600000)){
                  return '12:00/13:00';
                }else{
                  return Highcharts.dateFormat("%H:%M", this.value);
                }
              }else{
                var format = ChartExt.xDateFormatBy(this.axis.min, this.axis.max);
                return Highcharts.dateFormat(format, this.value);
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
                return HighStockExt.calTickPositions(this.dataMin, this.dataMax);
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
            top: 260,
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
            return {x: 50, y: 5};
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

  isCnDayMinutes: function(){
    return this.current_chart_datas_name == '1dm' && this.isCn();
  },

  isHkDayMinutes: function(){
    return this.current_chart_datas_name == '1dm' && this.market() == "hk";
  },

  isCn: function(){
    return ['sh', 'sz', 'gem'].indexOf(MarketIndexChart.exchange_symbol)>=0
  },

  market: function(){
    if (['sh', 'sz', 'gem'].indexOf(MarketIndexChart.exchange_symbol)>=0){
      return "cn";
    }else if(['hs'].indexOf(MarketIndexChart.exchange_symbol)>=0){
      return "hk";
    }else{
      return "us";
    }
  },

  needHandedCalTicks: function(){
    return !((MarketIndexChart.current_chart_datas_name == '1dm' && !this.isCn()) ||
      MarketIndexChart.current_chart_datas_name == '5dm')
  },

  isMinutes: function(){
    return ['1dm', '5dm'].indexOf(this.current_chart_datas_name) >= 0;
  },

  isWeekMinutes: function(){
    return this.current_chart_datas_name == '5dm';
  },

  setChartAttrs: function(min, max){
    var chart = $('#market_index_minute_chart').highcharts();
    var ts_interval = max - min;
    var tick_interval, show_last_label = true, align = 'left';
    if (ts_interval > 864000000){
      
    }else if(ts_interval > 86400000){
      tick_interval = 86400000;
      // show_last_label = false;
    }else{
      tick_interval = 3600000;
      align = 'center';
    }
    chart.xAxis[0].update({minTickInterval: tick_interval, showLastLabel: show_last_label, labels: {align: align}});
  },

// kline

  setKlineChart: function(type, index_stock_id){
    var tick_interval = type == "day" ? 604800000 : null;
    var market_kline_datas = MarketIndexChart.kline_datas[index_stock_id];
    var buttons = ChartExt.getKlineButtonsByType(type);
    $('#market_index_kline_chart').html("");

    if (market_kline_datas == undefined || market_kline_datas[type] == undefined){
      $.get("/ajax/stocks/" + index_stock_id + "/klines", {type: type}, function(datas){
        market_kline_datas = market_kline_datas || {};
        market_kline_datas[type] = ChartExt.getOhlcAndVolumeDatas(datas);
        MarketIndexChart.kline_datas[index_stock_id] = market_kline_datas;
        MarketIndexChart.drawKlineChart(market_kline_datas[type], buttons, tick_interval);
      })
    }else{
      MarketIndexChart.drawKlineChart(market_kline_datas[type], buttons, tick_interval);
    }
  },

  drawKlineChart: function(kline_datas, buttons, tick_interval){
    $('#market_index_kline_chart').highcharts('StockChart', {
        chart: {
          spacingTop: 0,
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
              ChartExt.addFirstXLabelTo(this, 6, this.xAxis[0].height+10);
            },
            redraw: function(){
              ChartExt.addFirstXLabelTo(this, 6, this.xAxis[0].height+10);
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
                  units: MarketIndexChart.klineGroupingUnits
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
                  units: MarketIndexChart.klineGroupingUnits
                }
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
            day: '%m.%d',
            week: '%m.%d',
            month: '%Y/%m',
            year: '%Y年'
          },
          events: {
            afterSetExtremes: function(e) {
            }
          },
          labels: {
            maxStaggerLines: 1
          },
          tickInterval: tick_interval,
          top: -10,
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
              if (MarketIndexChart.end_trade_timestamp >= this.value){
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
              align: 'left',
              format: '{value}'
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
              // distance: 10,
              // x: 20
            },
            top: 260,
            height: 60,
            tickPixelInterval: 30,
            gridLineColor: '#FFF',
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
                MarketIndexChart.setKlineInfo(Highcharts.dateFormat('%Y-%m-%d', this.x), point.point.open, point.point.high, 
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
      setTimeout(function () { $("#market_index_kline_chart .highcharts-button").hide(); }, 0);
      MarketIndexChart.showKlineInfosDiv();
      HighStockExt.addBorderLinesToKlineChart();
    });

    //初始化kline后，kline_info默认显示最后一条
    var last_datas = kline_datas.ohlc[kline_datas.ohlc.length-1];
    this.setKlineInfo(Highcharts.dateFormat('%Y-%m-%d', last_datas.x), last_datas.open, last_datas.high, 
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
  }
}



var OneDayMinute = {
  loadByTab: function(){
    var active_tab = $(".stockStatus a").filter(function(){return $(this).hasClass("active")}).first(),
        active_li_obj = active_tab.parent(),
        market_stock_id = active_li_obj.attr("data-id"), 
        market_end_ts = parseInt(active_li_obj.attr("data-utc-end-ts"));
    if (market_stock_id) this.AjaxUpdateMinutes(market_stock_id, market_end_ts);
  },

  AjaxUpdateMinutes: function(market_stock_id, market_end_ts){
    var now_timestamp = (new Date()).getTime();
    //由于数据延迟15分钟，所以加上20分钟
    if (now_timestamp <= market_end_ts+1200000){
      this.updateMinutesChart(market_stock_id, market_end_ts);
    }
  },

  updateMinutesChart: function(market_stock_id, market_end_ts){
    var market_minutes_datas = MarketIndexChart.minutes_datas[market_stock_id];
    if (!market_minutes_datas) return false;

    $.get("/ajax/stocks/"+market_stock_id+"/minutes", {}, function(datas){
      market_minutes_datas["one_day"] = MarketIndexChart.adjustedOneDayMinuteDatas(datas.one_day_minutes);
      if ($('#market_index_minute_chart').highcharts().xAxis[0].min+1000*3600*10 > market_end_ts 
        && $(".stockStatus a").filter(function(){return $(this).hasClass("active")}).first().parent().attr("data-id") == market_stock_id
        && $("#chart_type_btns li:eq(0)").hasClass("active") ){
        MarketIndexChart.showQuotePricesChart($("#chart_type_btns li:eq(0)"));
      }
    })
  }
}




var HighStockExt = {
  minute_chart: undefined,
  minute_chart_compare_value: null,
  minute_round_digit: 2,

  getMinuteChart: function(){
    return $('#market_index_minute_chart').highcharts();
  },

  actionsAfterMinuteChartRedrawed: function(){
    this.drawPreviousClosePriceLine();
    ChartExt.drawMinuteChartPercentYaxis(this.getMinuteChart(), this.minute_chart_compare_value, this.minute_round_digit);
  },

  pointMouseOverAction: function(point){
    var opts = {bottom_y: 256, show_minutes_time: MarketIndexChart.show_minutes_time, 
      compare_value: this.minute_chart_compare_value, minute_round_digit: this.minute_round_digit};
    ChartExt.pointMouseOverCrossHairs(point, opts);
  },

  pointMouseOutAction: function(point){
    ChartExt.pointMouseOutAction();
  },

  drawPreviousClosePriceLine: function(){
    if (MarketIndexChart.current_chart_datas_name == '1dm'){
      ChartExt.addLineByYValue(this.getMinuteChart(), MarketIndexChart.previous_close);
    }
  },

  setMinuteChartYaxisMinMax: function(minmax){
    //minmax = {min: 1, max:2}
    this.getMinuteChart().yAxis[0].update(minmax);
  },

  valueChangePercent: function(value){
    return ChartExt.valueChangePercent(value, this.minute_chart_compare_value, this.minute_round_digit);
  },

  //计算时分chart y轴坐标
  calTickPositions: function(data_min, data_max){
    var tick_value, increment, positions = [],
        max_interval = Math.max(Math.abs(this.minute_chart_compare_value-data_min), Math.abs(this.minute_chart_compare_value-data_max)),
        min = this.minute_chart_compare_value - max_interval;
        max = this.minute_chart_compare_value + max_interval;
    increment = this.adjustPositionIncrement(max, min);
    tick_value = this.adjustMinuteCompareValue(increment);
    for(var tick = AccMath.sub(tick_value, increment); tick + increment > min; tick = AccMath.sub(tick, increment)){
      positions.push(tick);
    }
    for(var tick = tick_value; tick - increment <= max; tick = AccMath.add(tick, increment)){
      positions.push(tick);
    }
    if (tick_value == positions.sort(function(a,b){return a-b;})[positions.length-1]) 
      positions.push(AccMath.add(tick_value, increment));

    return positions.sort(function(a,b){return a-b;});
  },

  adjustPositionIncrement: function(max, min){
    var multiples = [1, 2, 2.5, 5, 10], digit_num, multi_num;
    var increment = (max - min)/4;
    if (increment >= 1){
      digit_num = increment.toString().split(".")[0].length-1;
      multi_num = Math.pow(10, digit_num);
    }else{
      var right_string = increment.toString().split(".")[1];
      digit_num = right_string.length - parseInt(right_string).toString().length + 1;
      multi_num = Math.pow(0.1, digit_num);
    }
    for(index in multiples){
      var tmp_value = (multiples[index]*multi_num).round(digit_num+1)
      if (tmp_value >= increment){
        increment = tmp_value;
        break;
      }
    }
    return increment;
  },

  adjustMinuteCompareValue: function(tick_increment){
    var round_digit = tick_increment >= 0.1 ? 2 : 3;
    this.minute_round_digit = round_digit;
    this.minute_chart_compare_value = this.minute_chart_compare_value.round(round_digit);
    return this.minute_chart_compare_value;
  },

  minutesChartTooltips: function(points, position){
    var s = ChartExt.minutesChartTooltipTemplate(), 
        format = MarketIndexChart.show_minutes_time ? '%Y-%m-%d %H:%M' : '%Y-%m-%d',
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
    HighStockExt.minutesChartTooltips([price_point, volume_point], price_point);
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
    var chart = this.getMinuteChart(),
        top = chart.plotTop,
        y = top + 233,
        group_name = 'cs-minutes-chart-borders';
    ChartExt.addHorizonLineBy(chart, y, group_name);
  },

  addBorderLinesToKlineChart: function(){
    var chart = $("#market_index_kline_chart").highcharts(),
        y = 260,
        group_name = 'cs-klines-chart-borders';
    ChartExt.addHorizonLineBy(chart, y, group_name);
  }
}