//= require stock_order
//= require charts/ext

// 自选股
var FollowingStocks = {
  refreshStocks: function() {
    $.get("/ajax/users/following_stocks", {}, function(datas){
      for(i=0; i<datas.length; i++){
        FollowingStocks.renderItem(datas[i]);
      }
    })
  },

  loadTradingContent: function(stock_id, account_id){
    var follow_id = $("div[data-stock-id="+stock_id+"]").data().sid;
    $.post("/ajax/follow_stocks/"+follow_id+"/trade_stock", {account_id: account_id}, function(){
      
    })
  },
  
  //todo: no use?
  humanlizeNumber: function(number) {
    var f = parseFloat(number);
    if(f > 1000000000000){
      return accounting.formatMoney((f/1000000000000).toFixed(2), '') + "万亿";
    }else if(f > 100000000){
      return accounting.formatMoney((f/100000000).toFixed(2), '') + "亿";
    }else if(f > 10000){
      return accounting.formatMoney((f/10000).toFixed(2), '') + "万";
    }else{
      return accounting.formatMoney((f).toFixed(2), '');
    }
  },
  
  // options 接收的keys:
  // prefix ：前缀，默认无
  // postfix ：后缀，默认无
  // operator ：是否添加 + -符号，默认不添加
  // currency_format ：是否对value做货币千分位处理，默认不做
  upDownStyle: function(value, options){
    var value = parseFloat(value);
    var html = "";
    if(value === "" || value == undefined){
      return "<em>--</em>";
    }else{
      html = "<em class='";
      html += value>=0 ? "plus" : "mins";
      html += "'>";
      if(options.operator){
        html += value>=0 ? "+" : "-" ;
      }
      if(options.prefix){
        html += options.prefix;
      }
      if(options.currency_format){
        html += accounting.formatMoney(Math.abs(value).toFixed(2), '');
      }
      else{
        html += Math.abs(value).toFixed(2);
      }
      if(options.postfix){
        html += options.postfix;
      }
      html += "</em>";
      return html;
    }
  },
  
  renderItem: function(item) {
    var _node = $(".focusData .f_row").filter(function(){return $(this).attr("data-sid") == item.follow_id.toString()});

    var price = FormatValue.price(item.realtime_price),
        usd_rate = parseFloat(item.usd_rate),
        price_sort = FormatValue.toUsd(item.realtime_price, usd_rate),
        raisedown_class = FormatValue.upDownClass(item.change_from_previous_close),
        raisedown_operator = FormatValue.upDownOperator(item.change_from_previous_close),
        price_change = parseFloat(item.change_from_previous_close),
        price_change_sort = FormatValue.toUsd(item.change_from_previous_close, usd_rate),
        price_percent = parseFloat(item.change_percent).toFixed(2),
        trade_number = FormatValue.human_number(item.lastest_volume),
        trade_number_sort = item.lastest_volume ? parseFloat(item.lastest_volume) : 0,
        trade_amount = FormatValue.human_number(item.total_value_trade)
        market_value = FormatValue.money_number(item.adj_market_capitalization),
        market_value_sort = FormatValue.marketValueForSort(item.adj_market_capitalization, usd_rate);

    _node.find(".c3").html("<em class='" + raisedown_class + "'>" + price + "</em>");
    _node.find(".c3").attr("data-sort", price_sort);

    _node.find(".c4").html("<em class='" + raisedown_class + "'>" + raisedown_operator + price_change + "</em>");
    _node.find(".c4").attr("data-sort", price_change_sort);

    _node.find(".c5").html("<em class='" + raisedown_class + "'>" + raisedown_operator + price_percent + "%</em>");

    _node.find(".c6").html(trade_number);
    _node.find(".c6").attr("data-sort", trade_number_sort);

    _node.find(".c7").html(trade_amount);
    _node.find(".c7").attr("data-sort", item.total_value_trade);

    _node.find(".c8").html(market_value);
    _node.find(".c8").attr("data-sort", market_value_sort);
  },

  transformFollowStockInfos: function(data){
    var price = FormatValue.price(data.realtime_price),
        usd_rate = parseFloat(data.usd_rate),
        price_sort = FormatValue.toUsd(data.realtime_price, usd_rate),
        raisedown_class = FormatValue.upDownClass(data.change_from_previous_close),
        raisedown_operator = FormatValue.upDownOperator(data.change_from_previous_close),
        price_change = parseFloat(data.change_from_previous_close),
        price_change_sort = FormatValue.toUsd(data.change_from_previous_close, usd_rate),
        price_percent = parseFloat(data.change_percent).toFixed(2),
        trade_number = FormatValue.human_number(data.lastest_volume),
        trade_number_sort = parseFloat(data.lastest_volume),
        trade_amount = FormatValue.human_number(data.total_value_trade)
        market_value = FormatValue.money_number(data.adj_market_capitalization),
        market_value_sort = FormatValue.marketValueForSort(data.adj_market_capitalization, usd_rate),
        followed_price_sort = FormatValue.toUsd(data.followed_price, usd_rate);
    return {
              market: data.market_area,
              sid: data.follow_id, 
              stock_id: data.id,
              code: data.symbol,
              name: data.truncated_com_name,
              remark: data.notes || '',
              link: '/stocks/' + data.id,
              raisedown: raisedown_class,
              price: price,
              price_sort: price_sort,
              price_change: raisedown_operator + price_change,
              price_change_sort: price_change_sort,
              price_percent: raisedown_operator + price_percent + '%',
              trade_number: trade_number,
              trade_number_sort: trade_number_sort,
              trade_amount: trade_amount, 
              market_value: market_value,
              market_value_sort: market_value_sort,
              pe: data.adj_pe_ratio,
              score: data.score,
              score_width: parseFloat(data.score) * 20,
              followed_price: data.followed_price,
              followed_price_sort: followed_price_sort
            }
  }
}



var MinuteChart = {
  stock_datas: {},

  init: function(stock_id){
    if(MinuteChart.stock_datas[stock_id] == undefined){
      MinuteChart.stock_datas[stock_id] = "loading";
      $.get("/ajax/stocks/"+stock_id+"/minutes", {}, function(datas){
        var minutes_prices = MinuteChart.getPrices(datas);
        MinuteChart.stock_datas[stock_id] = {datas: minutes_prices, previous_close: datas.previous_close, start_trade_timestamp: datas.start_trade_timestamp, end_trade_timestamp: datas.end_trade_timestamp};
        MinuteChart.draw(minutes_prices, datas.previous_close, datas.start_trade_timestamp, datas.end_trade_timestamp);
      })
    }else{
      if (MinuteChart.stock_datas[stock_id] == "loading") return;
      var stock_datas = MinuteChart.stock_datas[stock_id];
      MinuteChart.draw(stock_datas.datas, stock_datas.previous_close, stock_datas.start_trade_timestamp, stock_datas.end_trade_timestamp);
    }
  },

  getPrices: function(datas){
    var prices = [], ori_datas = datas.one_day_minutes, market = datas.market,
      dataLength = ori_datas.length, end_trade_ts = datas.end_trade_timestamp,
      exist_end_ts = ori_datas.length>0 ? ori_datas.slice(-1)[0][0] : end_trade_ts;

    if (ori_datas.length == 0){
      return [{x: datas.start_trade_timestamp, y: datas.previous_close}];
    }
      
    for (i = 0; i < dataLength; i++) {
      prices.push({x: ori_datas[i][0], y: ori_datas[i][1]});
    }
    var appended_prices = ChartExt.minuteDatasAppendedPoints(market, end_trade_ts, exist_end_ts, 60000);
    return prices.concat(appended_prices);
  },

  draw: function(chart_datas, previous_close, x_min, x_max){
    $(".chartArea").highcharts('StockChart', {
      chart: {
        marginBottom: 2,
        marginTop: 2,
        marginLeft: 60,
        marginRight: 2,
        plotBorderWidth: 1,
        backgroundColor: '#f6f6f6',
        plotBackgroundColor: 'white'
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
          offset: 0,
          gridLineColor: '#F0F0F0',
          gridLineWidth: 1,
          showEmpty: true,
          // ordinal: false,
          min: x_min,
          max: x_max,
          tickPositioner: function(){
            var tickers = [], interval = (x_max - x_min)/2;
            // for(i=0; i<6; i++){
            //   tickers.push(x_min + interval * (i+1));
            // }
            tickers = [x_min + interval];
            return tickers;
          }
      },
      yAxis: {
          labels: {
            enabled: true,
            align: "right",
            useHTML: true,
            formatter: function () {
              if(this.value > previous_close){
                return "<span style='color: #e4462e;'>" + this.value + "</span>";
              }else if(this.value < previous_close){
                return "<span style='color: #4daf7b;'>" + this.value + "</span>";
              }else{
                return this.value;
              }
            }
          },
          title: {
            enabled: false
          },
          offset: -10,
          opposite: false,
          gridLineColor: '#F0F0F0',
          gridLineWidth: 1,
          tickPositioner: function(){
            if (this.dataMin != null && this.dataMax != null){
              return MinuteChart.calTickPositions(previous_close, this.dataMin, this.dataMax);
            }
          },
          plotLines : [{
              value : previous_close,
              color : 'red',
              dashStyle : 'dash',
              width : 1,
              zIndex:100
          }]
      },
      tooltip: {
        crosshairs: [false, true],
        enabled: false
      },
      legend: {
          enabled: false
      },
      rangeSelector: {
        enabled: false
      },
      navigator: {
        enabled: false
      },
      scrollbar: {
        enabled: false
      },
      plotOptions: {
          line: {
              // fillColor: '#EBEAEA',
              color: "#4183c4",
              lineWidth: 1.2,
              marker: {
                  enabled: false
              },
              shadow: false,
              states: {
                  hover: {
                      lineWidth: 1.2
                  }
              },
              threshold: null,
              enableMouseTracking: false
          }
      },
      series: [{
          // type: 'area',
          name: '52week prices',
          // pointInterval: 24 * 3600 * 1000,
          data: chart_datas
      }]
    })
  },

  // 此处使用较特殊处理方法，现其它分时chart公共方法见charts/ext.js
  //计算时分chart y轴坐标
  calTickPositions: function(tick_value, data_min, data_max){
    // if (data_min == data_max && tick_value == data_max) return [AccMath.sub(tick_value, 0.1), tick_value, AccMath.add(tick_value,0.1)];
    return ChartExt.calYTickPositions(tick_value, data_min, data_max);

    // var min, max, tick_value, increment, positions = [];
    // min = Math.min(tick_value, data_min);
    // max = Math.max(tick_value, data_max);
    // increment = this.adjustPositionIncrement(max, min);
    // for(var tick = AccMath.sub(tick_value, increment); tick + increment > min; tick = AccMath.sub(tick, increment)){
    //   positions.push(tick);
    // }
    // for(var tick = tick_value; tick - increment <= max; tick = AccMath.add(tick, increment)){
    //   positions.push(tick);
    // }
    // if (tick_value == positions.sort(function(a,b){return a-b;})[positions.length-1])
    //   positions.push(AccMath.add(tick_value, increment));

    // return positions.sort(function(a,b){return a-b;});
  },

  // adjustPositionIncrement: function(max, min){
  //   var multiples = [1, 2, 2.5, 5, 10], digit_num, multi_num;
  //   var increment = (max - min)/4;
  //   if (increment >= 1){
  //     digit_num = increment.toString().split(".")[0].length-1;
  //     multi_num = Math.pow(10, digit_num);
  //   }else{
  //     var right_string = increment.toString().split(".")[1];
  //     digit_num = right_string.length - parseInt(right_string).toString().length + 1;
  //   }
  //   for(index in multiples){
  //     var tmp_value = (multiples[index]*multi_num).round(digit_num+1)
  //     if (tmp_value >= increment){
  //       increment = tmp_value;
  //       break;
  //     }
  //   }
  //   return increment;
  // }
}


// 初始化对象 c_MyFocus
var c_MyFocus = new CS_FOCUS({
  group_create: function(name, callback){
    $.post("/ajax/follow_stock_tags", {name: name}, function(response){
      if(response.status){
        var gid = response.data.id;
        var data = {'id':gid,'name':name,child:[]};
        callback(data);
      }
    })
  },
  group_rename: function(gid, name, callback){
    $.post("/ajax/follow_stock_tags/" + gid + "/rename", {name: name}, function(response){
      if(response.status){
        var data = {'id':gid,'name':name,child:[]};
        callback(data);
      }
    })
  },
  group_remove: function(gid, del, callback){
    $.post("/ajax/follow_stock_tags/" + gid + "/delete", {delete_follows: del}, function(response){
      var data = {'id':gid,'status':response.status};
      callback(data);
    })
  },
  group_append: function(gid, sids, callback){
    sids = sids || [];
    $.post("/ajax/follow_stock_tags/" + gid + "/add", {follow_ids: sids}, function(response){
      var data = {'id':gid,'status':response.status};
      callback(data);
    })
  },
  group_sorting: function(gids, callback){
    $.post("/ajax/follow_stock_tags/update_sort", {tag_ids: gids}, function(response){
      var data = {'status':response.status};
      callback(data);
    })
  },
  stock_append: function(sid, gid, callback) {
    $.post("/ajax/follow_stocks/"+sid+"/tag", {tag_id: gid}, function(response){
      var data = FollowingStocks.transformFollowStockInfos(response.data);
      callback(data);
    })
  },
  stock_remove: function(sid, gid, callback) {
    $.post("/ajax/follow_stocks/"+sid, {_method:'delete', tag_id:gid}, function(response){
      var data = {'status':response.status};
      callback(data);
    })
  },
  stock_remark: function(sid, remark, callback) {
    $.post("/ajax/follow_stocks/"+sid+"/update_notes", {notes: remark}, function(response){
      var data = {'status':response.status,remark:remark};
      callback(data);
    })
  },
  stock_sorting: function(sids, callback) {
    $.post("/ajax/follow_stocks/update_sort", {follow_ids: sids}, function(response){
      var data = {'status':response.status};
      callback(data);
    })
  },
  stock_hoverin: function(stock_id, remark, callback) {
    MinuteChart.init(stock_id);
  },
  stock_trade: function(sid, callback) {
    $("#orderTable").html("");
    $.post("/ajax/follow_stocks/"+sid+"/trade_stock", {}, function(){
      callback({});
    })
  },
  stock_follow: function(stock_id, callback){
    $.post("/ajax/stocks/" + stock_id + "/follow", {}, function(response){
      callback({sid: response.follow_id});
    })
  },
  stock_search: function(term, callback){
    $.get('/ajax/stocks/search', {term: term, limit: 10, search_all: true}, function(data){
      callback(data);
    })
  }
});

c_MyFocus.init();
