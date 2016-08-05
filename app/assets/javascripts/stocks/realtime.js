//股票实时数据更新

var StockRealtime = {
  rtHeartbeat: function(){
    var now_timestamp = (new Date()).getTime();
    //由于数据延迟15分钟，所以加上20分钟
    if (now_timestamp >= StockShow.start_trade_timestamp_of_utc && now_timestamp <= StockShow.end_trade_timestamp_of_utc+1200000){
      $.get("/ajax/stocks/" + StockShow.stock_id + "/rt.js")
    }
  },

  update: function(datas){
    var is_cn = datas.market == "cn",
        volume_unit = is_cn ? "手" : "",
        rt_price = parseFloat(datas.last), 
        rt_volume = parseInt(datas.volume),
        rt_change_from_previous_close = parseFloat(datas.change_from_previous_close), 
        rt_change_percent = parseFloat(datas.percent_change_from_previous_close), 
        previous_close = rt_price - rt_change_from_previous_close, 
        rt_bid_prices = accounting.formatMoney(parseFloat(datas.bid_prices), ""), 
        rt_bid_sizes = StockRealtime.formatVolume(parseInt(datas.bid_sizes), is_cn), 
        rt_offer_prices = accounting.formatMoney(parseFloat(datas.offer_prices), ""), 
        rt_offer_sizes = StockRealtime.formatVolume(parseInt(datas.offer_sizes), is_cn), 
        rt_low = accounting.formatMoney(parseFloat(datas.low), ""), 
        rt_high = accounting.formatMoney(parseFloat(datas.high), ""), 
        rt_low52_weeks = accounting.formatMoney(parseFloat(datas.low52_weeks), ""), 
        rt_high52_weeks = accounting.formatMoney(parseFloat(datas.high52_weeks), ""), 
        rt_logs = datas.rt_logs,
        old_price = parseFloat($("#stock_realtime_price em").text()), 
        rt_class = rt_change_from_previous_close>0 ? "plus" : "mins", 
        prefix_operator = rt_change_from_previous_close>0 ? "+" : "",
        old_bid_price = parseFloat($("#rt_bid").text().replaceAll(",", "")), 
        bid_price_am_class = parseFloat(datas.bid_prices) > old_bid_price ? "plus" : "mins",
        old_bid_size = $("#rt_bid_size").text().replace(volume_unit, ""),
        old_offer_price = parseFloat($("#rt_offer").text().replaceAll(",", "")),
        offer_price_am_class = parseFloat(datas.offer_prices) > old_offer_price ? "plus" : "mins",
        old_offer_size = $("#rt_offer_size").text(),
        price_class;

    $(".tradeTime i:eq(1)").text(datas.trade_time);
    $(".tradeTime i:eq(1)").backgroundAnim('gray');

    if (rt_price != old_price){
      var animate_class = rt_price>old_price ? "plus" : "mins";
      var rt_price_str = accounting.formatMoney(rt_price, "");
      $("#stock_realtime_price em").attr("class", rt_class).text(rt_price_str);
      $('#stock_realtime_price').backgroundAnim(animate_class);
      var rt_up_down_str = prefix_operator + accounting.formatMoney(rt_change_from_previous_close, "");
      rt_up_down_str += "(" + prefix_operator + accounting.formatMoney(rt_change_percent, "") + "%)";
      $("#stock_realtime_updown em").attr("class", rt_class).text(rt_up_down_str);
      $("#stock_realtime_updown").backgroundAnim(animate_class);

      // StockRealtime.drawRealtimePointToChart(rt_price, datas.trade_time);
    }
    if (parseFloat(datas.bid_prices) != old_bid_price){
      $("#rt_bid").text(rt_bid_prices);
      price_class = parseFloat(datas.bid_prices) - previous_close >= 0 ? "plus" : "mins";
      $("#rt_bid").backgroundAnim(bid_price_am_class).removeAttr("class").addClass(price_class);
      $("#rt_bid_size").text(rt_bid_sizes + volume_unit);
    }else if(rt_bid_sizes != old_bid_size){
      var bid_size_am_class = StockRealtime.compareVolume(rt_bid_sizes, old_bid_size) ? "plus" : "mins";
      $("#rt_bid_size").text(rt_bid_sizes + volume_unit);
      $("#rt_bid_size").backgroundAnim(bid_size_am_class);
    }
    if (parseFloat(datas.offer_prices) != old_offer_price){
      $("#rt_offer").text(rt_offer_prices);
      price_class = parseFloat(datas.offer_prices) - previous_close >= 0 ? "plus" : "mins";
      $("#rt_offer").backgroundAnim(offer_price_am_class).removeAttr("class").addClass(price_class);
      $("#rt_offer_size").text(rt_offer_sizes + volume_unit);
    }else if(rt_offer_sizes != old_offer_size){
      var offer_size_am_class = StockRealtime.compareVolume(rt_offer_sizes, old_offer_size) ? "plus" : "mins";
      $("#rt_offer_size").text(rt_offer_sizes + volume_unit);
      $("#rt_offer_size").backgroundAnim(offer_size_am_class);
    }
    $("#day_low").text(rt_low);
    $("#day_high").text(rt_high);
    $("#year_low").text(rt_low52_weeks);
    $("#year_high").text(rt_high52_weeks);

    $("#StockTradeInfo li").remove();
    $.each(rt_logs, function(index){
      var rt_log = rt_logs[index].split(","),
          log_price = rt_log[1], 
          log_volume = StockRealtime.formatVolume(parseInt(rt_log[2]), is_cn), 
          log_time = rt_log[3].split(" ")[1], 
          price_class = parseFloat(log_price) - previous_close >= 0 ? "plus" : "mins",
          li_html;
      li_html = "<li><span>"+log_time+"</span><span class='"+price_class+"'>"+log_price+"</span><span>"+log_volume+volume_unit+"</span></li>"
      $("#StockTradeInfo").append(li_html);
    })

    this.updateKline(rt_price, parseFloat(datas.high), parseFloat(datas.low), rt_volume);
    set_title(document.title.split(" ")[0], accounting.formatMoney(rt_price, ""), accounting.formatMoney(rt_change_percent, "")+"%", $("dl.stockName dt span b").text());
  },

  formatVolume: function(volume, is_cn){
    volume = is_cn ? volume/100 : volume
    if (volume >= 100000000){
      return accounting.formatMoney(volume/100000000, "") + "亿";
    }else if(volume >=10000){
      return accounting.formatMoney(volume/10000, "") + "万";
    }else{
      return accounting.formatNumber(volume);
    }
  },

  compareVolume: function(volume1, volume2){
    if (volume1.endsWith("万") && !volume2.endsWith("万")){
      return true;
    }else if(!volume1.endsWith("万") && volume2.endsWith("万")){
      return false;
    }else{
      return parseFloat(volume1.replaceAll(",", "")) > parseFloat(volume2.replaceAll(",", ""));
    }
  },

  drawRealtimePointToChart: function(price, trade_time_str){
    var trade_ts = (new Date(trade_time_str + " +0000")).getTime(),
        realtime_point = {x: trade_ts, y: price}, 
        current_time = new Date(), 
        one_minute_ago_ts = (current_time).getTime() - current_time.getTimezoneOffset()*60000 - 1000*60;
    if (one_minute_ago_ts > trade_ts) return false;
    console.log(one_minute_ago_ts);
    console.log(trade_ts);
    if ($("#time_period li:eq(0)").hasClass("active")){
      var chart = $("#stock_chart").highcharts(), 
          renderer = chart.renderer, x = StockRealtime.findLatestPointXAxisOfPrice(chart), 
          y = HighStockExt.calculateValueYPixelOfMinuteChart(chart, price);
      // var start_ts = $("#time_period li:eq(0)").attr("data"), 
      //     end_ts = StockShow.end_trade_timestamp_of_utc;
      // StockShow.updateChartSeriesData(start_ts, end_ts);
      // $("#stock_chart").highcharts().series[0].addPoint([trade_ts, price], false);

      //next methods
      // renderer.circle(point.plotX+chart.plotLeft, 196.66666666666634, 5).add();
    }
  },

  findLatestPointXAxisOfPrice: function(chart){
    var points = chart.series[0].data, latest_point = points[0], max_ts;
    $.each(points, function(index){
      if (points[index].x > latest_point.x && points[index].y != null){
        latest_point = points[index];
      }
    })
    return latest_point.plotX + chart.plotLeft + 2.6;
  },

  updateKline: function(realtime_price, high, low, volume){
    this.updateKlineByType("day", realtime_price, high, low, volume);
    this.updateKlineByType("week", realtime_price, high, low, volume);
    this.updateKlineByType("month", realtime_price, high, low, volume);
  },

  //现在缺陷：拖动时间范围后，最后一点不在可见范围无法动态更新(能更新数值，但图没重绘)；开盘后打开的页面才能根据实时数据动态更新
  updateKlineByType: function(type, realtime_price, high, low, volume){
    var kline_datas = StockShow.kline_datas[type];
    if (!kline_datas) return;
    var ohlc = kline_datas.ohlc,
        last_point = ohlc[ohlc.length - 1],
        last_last_point = ohlc[ohlc.length - 2],
        volumes = kline_datas.volume, 
        last_volume = volumes[volumes.length - 1],
        now_ts = (new Date()).getTime();
    if (last_point.x + 24*3600000 < now_ts) return;

    last_point.high = Math.max(high, last_point.high);
    last_point.low = Math.min(low, last_point.low);
    last_point.close = realtime_price;
    if (last_last_point){
      last_point.change = last_point.close - last_last_point.close;
      last_point.change_percent = last_point.change*100/last_last_point.close;
    }
    // month/week的实时量不好处理
    if (type == "day") last_volume.y = volume;

    var chart_index = {day: 1, week: 2, month: 3}, 
        chart_type_index = chart_index[type],
        current_index = $("#chart_type_btns .active").index(),
        h = $('#kline_chart').highcharts(),
        ohlc_points = h.series[0].points,
        last_ohlc_point = ohlc_points[ohlc_points.length-1],
        volume_points = h.series[5].points,
        last_volume_point = volume_points[volume_points.length - 1],
        color = (last_ohlc_point.open < last_ohlc_point.close) ? '#e4462e' : '#4daf7b';
    if ((chart_type_index == current_index) && (last_ohlc_point.x == last_point.x)){
      last_volume_point.update({y: last_volume.y, color: color}, false);
      last_ohlc_point.update({high: last_point.high, low: last_point.low, close: last_point.close, change: last_point.change, change_percent: last_point.change_percent}, false);
    }
  }
}