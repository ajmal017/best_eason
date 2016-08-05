//chart 公用方法
var ChartExt = {
  setChartOpions: function(){
    Highcharts.setOptions({
      lang : {
        rangeSelectorFrom : "",
        rangeSelectorTo : "至",
        rangeSelectorZoom : "",
        // shortMonths:['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],  
        weekdays:['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
      }
    });
  },

  getKlineButtonsByType: function(type){
    switch (type){
      case 'week':
        return [{type: 'month', count: 12, text: '1年'}];
      case 'month':
        return [{type: 'year', count: 3, text: '3年'}];
      default: 
        return [{type: 'month', count: 3, text: '3月'}];
    }
  },

  getKlineXaixsIntervalByType: function(type){
    switch (type){
      case 'week':
        return 2*91*24*3600*1000;
      case 'month':
        return 3*365*24*3600*1000;
      default: 
        return 30*24*3600*1000;
    }
  },

  humanizedVolume: function(volume){
    if (!volume && volume!=0) return '';
    if (volume >= 100000000){
      return (volume/100000000).toFixed(2) + "亿股";
    }else if (volume >= 10000){
      return (volume/10000).toFixed(2) + "万股";
    }else{
      return volume.toFixed(2) + "股";
    }
  },

  upOrDownStyle: function(value, is_percent){
    var unit = is_percent ? "%" : "";
    if (value >= 0){
      return "<span style='color:red;'>" + calPrefix(value) + value.toFixed(2) + unit + "</span>";
    }else{
      return "<span style='color:#00A600;'>" + calPrefix(value) + value.toFixed(2) + unit + "</span>";
    }
  },

  xDateFormatBy: function(min, max){
    var ts_interval = max - min;
    if (ts_interval > 15552000000){
      return '%Y/%m';
    }else if(ts_interval > 86400000){
      return '%m-%d';
    }else{
      return '%H:%M';
    }
  },

  // 根据klines数据抽取成chart使用格式
  getOhlcAndVolumeDatas: function(ori_datas){
    var ohlc = [], volume = [], ma5_datas = [], ma10_datas = [], 
      ma20_datas = [], ma30_datas = [], dataLength = ori_datas.length;
      
    for (i = 0; i < dataLength; i++) {
      var price_change = i==0 ? 0 : ori_datas[i].close - ori_datas[i-1].close,
          price_change_percent = i==0 ? 0 : price_change*100/ori_datas[i-1].close,
          ma5 = this.calKlineMaData(ori_datas, i, 5),
          ma10 = this.calKlineMaData(ori_datas, i, 10),
          ma20 = this.calKlineMaData(ori_datas, i, 20),
          ma30 = this.calKlineMaData(ori_datas, i, 30),
          color;
      if (ori_datas[i].open == ori_datas[i].close){
        color = price_change_percent > 0 ? '#e4462e' : '#4daf7b';
      }else if (ori_datas[i].open < ori_datas[i].close){
        color = '#e4462e';
      }else{
        color = '#4daf7b';
      }

      ohlc.push({
        x: ori_datas[i].date, // the date
        y: ori_datas[i].high, 
        open: ori_datas[i].open, // open
        high: ori_datas[i].high, // high
        low: ori_datas[i].low, // low
        close: ori_datas[i].close, // close
        change: price_change,
        change_percent: price_change_percent,
        volume: ori_datas[i].volume, 
        ma5: ma5.toFixed(2),
        ma10: ma10.toFixed(2),
        ma20: ma20.toFixed(2),
        ma30: ma30.toFixed(2),
        color: color,
        lineColor: color,
        kline: true
      });
      
      volume.push({x: ori_datas[i].date, y: ori_datas[i].volume, color: color})

      ma5_datas.push([ori_datas[i].date, ma5]);
      ma10_datas.push([ori_datas[i].date, ma10]);
      ma20_datas.push([ori_datas[i].date, ma20]);
      ma30_datas.push([ori_datas[i].date, ma30]);
    }
    return {'ohlc': ohlc, 'volume': volume, 'ma5': ma5_datas, 'ma10': ma10_datas, 'ma20': ma20_datas, 'ma30': ma30_datas}
  },

  //计算ma5，ma10，ma20，ma30数据
  calKlineMaData: function(datas, cur_index, cal_count){
    var start_index = cur_index < cal_count ? 0 : cur_index - cal_count + 1;
    var total_value = 0, real_value_count = 0;
    for(j=start_index; j<=cur_index; j++){
      total_value += datas[j].close;
      real_value_count += 1;
    }
    return total_value/real_value_count;
  },

  //datas 是chart x轴所有数据
  calXTicks: function(datas, data_min, data_max){
    var x_times = [], ticks = [], interval, left_interval, index, grid_num = 5;
    $.each(datas, function(i){
      if(datas[i] >= data_min && datas[i] <= data_max){
        x_times.push(datas[i]);
      }
    })
    x_times = x_times.sort();
    if (x_times.length < 10){
      return [];
    }else if(x_times.length < 15){
      grid_num = 2;
    }else if(x_times.length < 20){
      grid_num = 3;
    }
    interval = Math.floor(x_times.length/grid_num);
    left_interval = x_times.length - interval*grid_num;
    index = interval - 1;
    for(i=1; i<grid_num; i++){
      index = i==1 ? index : index + interval;
      if (left_interval > 0){
        index += 1;
        left_interval -= 1;
      }
      ticks.push(x_times[index]);
    }
    return ticks;
  },

  calYTickPositions: function(compare_value, data_min, data_max){
    if (data_min == data_max && compare_value == data_max) return [AccMath.sub(compare_value, 0.1), compare_value, AccMath.add(compare_value,0.1)];
    
    var min, max, tick_value, increment, positions = [], digit_num, round_num,
        max_interval = Math.max(Math.abs(compare_value-data_min), Math.abs(compare_value-data_max));
    increment = AccMath.div(AccMath.sub(data_max, data_min),4);
    max = compare_value + max_interval;
    min = compare_value - max_interval;
    
    if (increment >= 1){
      // digit_num = increment.toString().split(".")[0].length-1;
      digit_num = 1;
    }else{
      var right_string = increment.toString().split(".")[1] || "0";
      digit_num = right_string.length - parseInt(right_string).toString().length + 1;
    }
    round_num = digit_num + 1;

    positions.push(max.round(round_num));
    positions.push((compare_value + max_interval/2.0).round(round_num));
    positions.push(min.round(round_num));
    positions.push((compare_value - max_interval/2.0).round(round_num));
    positions.push(compare_value.round(round_num));
    return positions.sort(function(a,b){return a-b;});
  },

  //分时图后端补点
  minuteDatasAppendedPoints: function(market, close_ts, exist_end_ts, interval){
    var times = Math.floor((close_ts - exist_end_ts)/interval),
        open_ts = close_ts - 25200000,
        appended_points = [], noon_range = [];
        if (market == "cn"){
          noon_range = [close_ts-12600000, close_ts-7200000]
        }else if(market == "hk"){
          noon_range = [close_ts-14400000, close_ts-10800000]
        };
    for(i=0; i<times; i++){
      var x = exist_end_ts+(i+1)*interval;
      if (noon_range.length==0 || (x <= noon_range[0] && x >= open_ts) || x>= noon_range[1] ){
        appended_points.push({x: x, y: null});
      }
    }
    return appended_points;
  },

  //添加最小x值label到某一位置
  addFirstXLabelTo: function(chart, x_pixel, y_pixel){
    $(".highcharts-cs-x-first-label").remove();

    var format = ChartExt.xDateFormatBy(chart.xAxis[0].min, chart.xAxis[0].max),
        text = Highcharts.dateFormat(format, chart.xAxis[0].min),
        group = chart.renderer.g("cs-x-first-label").attr({zIndex: 7}).add();

    chart.renderer.text(text, x_pixel, y_pixel).css({color:'#606060',"text-anchor":"start"}).add(group);
  },

  //一日分时，第一个、最后一个位置调整
  adjustOneDayMinutesLabels: function(chart_width){
    $(".highcharts-xaxis-labels").each(function(){
      $(this).find("text:first").attr("x", 6).attr("text-anchor", "start");
      $(this).find("text:last").attr("x", chart_width-6).attr("text-anchor", "end");
    })
  },

  //根据y值画0线红线
  addLineByYValue: function(chart, y_value){
    var r = chart.renderer,
        left = chart.plotLeft,
        width = chart.plotWidth;
    var adjusted_y = ChartExt.calculateValueYPixelOfMinuteChart(chart, y_value) || 126;
    var line = r.path(['M', left, adjusted_y, 'L', left + width, adjusted_y])
        .attr({'fill':'none', 'stroke-width': 1, 'zIndex':2, 
          'opacity':0.9, stroke: '#e4462e', dashstyle: '5 8 3 9'
        }).add();
    return line;
  },

  //平行于x轴的线，现在用户是用于画volue上面的边
  addHorizonLineBy: function(chart, y, group_name){
    var r = chart.renderer,
        left = chart.plotLeft,
        top = chart.plotTop,
        width = chart.plotWidth,
        height = chart.plotHeight;

    var line_group = r.g(group_name).attr({zIndex: 7}).add();

    r.path(['M', left, y, 'L', left + width, y])
      .attr({ 'stroke-width': 1, opacity: 1, stroke: '#F0F0F0', zIndex: 5}).add(line_group);
  },

  //画百分比y轴，compare_value为计算百分比对比值; 右边volume yaxis
  drawMinuteChartPercentYaxis: function(chart, compare_value, minute_round_digit){
    $(".highcharts-percent-yaxis").remove();

    var r = chart.renderer, left = chart.plotLeft, width = chart.plotWidth
        percent_yaxis_group = r.g("percent-yaxis").attr({zIndex: 7}).add(),
        yaxis_values = chart.yAxis[0].tickPositions;
    $.each(yaxis_values.slice(0, yaxis_values.length), function(index){
      var percent = ChartExt.valueChangePercent(yaxis_values[index], compare_value, minute_round_digit),
          y = ChartExt.calculateValueYPixelOfMinuteChart(chart, yaxis_values[index]),
          font_color = percent==0 ? "gray" : (percent>=0 ? "#e4462e" : "#4daf7b"),
          fixed_y = index==(yaxis_values.length-1) ? y+12 : y-2;
      r.text(yaxis_values[index], 6, fixed_y).css({color: font_color, "text-anchor": "start"}).add(percent_yaxis_group);
      r.text(percent.toFixed(2)+"%", left + width - 6, fixed_y).css({color: font_color, "text-anchor": "end"}).add(percent_yaxis_group);
    })
  },

  calculateValueYPixelOfMinuteChart: function(chart, y_value){
    var line_chart_height = 200;
    var y_axis = chart.yAxis[0],
        y_min = y_axis.min,
        y_max = y_axis.max,
        top = chart.plotTop;
    return (y_max-y_value)*line_chart_height/(y_max-y_min) + top;
  },

  valueChangePercent: function(value, compare_value, minute_round_digit){
    if (compare_value.round(minute_round_digit) == value) return 0;
    value = this.invertValueString(value).toFixed(minute_round_digit);
    return compare_value==0 ? 0 : (value-compare_value)*100/compare_value;
  },

  invertValueString: function(value_str){
    var value = parseFloat(value_str);
    if (/.*k$/.test(value_str)){
      return value*1000;
    }else{
      return value;
    }
  },

  //分时图十字线
  //opts 参数： bottom_y, show_minutes_time, compare_value, minute_round_digit
  pointMouseOverCrossHairs: function(point, opts){
    var chart = point.series.chart,
        r = chart.renderer,
        left = chart.plotLeft,
        top = chart.plotTop,
        width = chart.plotWidth,
        height = chart.plotHeight,
        x = point.plotX,
        y = point.plotY;

    if (point.series.options.enabledCrosshairs) {
      var cross_hairs_group = r.g("cross-hairs").attr({zIndex: 7}).add();

      r.path(['M', left, top + y, 'L', left + width, top + y])
          .attr({ 'stroke-width': 1, opacity: 0.5, stroke: 'black', zIndex: 2}).add(cross_hairs_group);
      r.path(['M', left + x, top, 'L', left + x, opts.bottom_y])
          .attr({'stroke-width': 1, opacity: 0.5, stroke: 'black', zIndex: 2 }).add(cross_hairs_group);
      this.addYvalueAndComparePercent(point, cross_hairs_group, chart, opts);
    }
  },

  //跟随十字线动态左右上下显示一个text
  addYvalueAndComparePercent: function(point, g_group, chart, opts){
    var r = chart.renderer, left = chart.plotLeft, top = chart.plotTop, 
        y_value = point.y, x_value = point.x, width = chart.plotWidth, y = point.plotY,
        bottom_rect_width = opts.show_minutes_time ? 40 : 70,
        left_text = y_value>=10000 ? Math.round(y_value) : y_value.round(opts.minute_round_digit),
        right_text = ChartExt.valueChangePercent(y_value, opts.compare_value, opts.minute_round_digit).toFixed(2)+"%",
        bottom_text = opts.show_minutes_time ? Highcharts.dateFormat('%H:%M', x_value) : Highcharts.dateFormat('%Y-%m-%d', x_value),
        bottom_rect_x, bottom_text_x;

    if (point.plotX <= bottom_rect_width/2){
      bottom_rect_x = 0;
      bottom_text_x = bottom_rect_width/2;
    }else if (point.plotX>= (width-bottom_rect_width/2)){
      bottom_rect_x = width - bottom_rect_width;
      bottom_text_x = width - bottom_rect_width/2;
    }else{
      bottom_rect_x = left + point.plotX - bottom_rect_width/2;
      bottom_text_x = left + point.plotX;
    }

    r.rect(left, top + y - 10, 50, 20, 0)
        .attr({'stroke-width': 1, stroke: '#dedede', fill: '#f0f0f0', zIndex: 8}).add(g_group);
    r.rect(left+width-50, top + y - 10, 50, 20, 0)
        .attr({'stroke-width': 1, stroke: '#dedede', fill: '#f0f0f0', zIndex: 8}).add(g_group);
    r.rect(bottom_rect_x, top + 215, bottom_rect_width, 20, 0)
        .attr({'stroke-width': 1, stroke: '#dedede', fill: '#f0f0f0', zIndex: 8}).add(g_group);

    r.text(left_text, left+5, top + y + 5).attr({zIndex: 9, "text-anchor": "start"}).add(g_group);
    r.text(right_text, left+width-5, top + y + 5).attr({zIndex: 9, "text-anchor": "end"}).add(g_group);
    r.text(bottom_text, bottom_text_x, opts.bottom_y).attr({zIndex: 9, "text-anchor": "middle"}).add(g_group);
  },

  pointMouseOutAction: function(point){
    $(".highcharts-cross-hairs").remove();
  },

  minutesChartTooltipTemplate: function(){
    return '<span style="margin-left:6px">当前价：%current_price%<span style="color:%percent_color%;">(%operator%%percent%%)</span><span style="margin-left:10px">成交量：%volume%</span><span style="margin-left:10px"></span>时间：%datetime%</span>';
  }
}



// highchart 公共扩展
var HighChartExt = {
  //hacked
  hackPointerRunPointActions: function(){
    // var originalRunPointActions = Highcharts.Pointer.prototype.runPointActions;
    Highcharts.Pointer.prototype.runPointActions = function (e) {
      var pointer = this,
          chart = pointer.chart,
          series = chart.series,
          tooltip = chart.tooltip,
          followPointer,
          point,
          points,
          hoverPoint = chart.hoverPoint,
          hoverSeries = chart.hoverSeries,
          i,
          j,
          distance = chart.chartWidth,
          index = pointer.getIndex(e),
          anchor;

      // shared tooltip
      if (tooltip && pointer.options.tooltip.shared && !(hoverSeries && hoverSeries.noSharedTooltip)) {
        points = [];

        // loop over all series and find the ones with points closest to the mouse
        i = series.length;
        for (j = 0; j < i; j++) {
          if (series[j].visible &&
              series[j].options.enableMouseTracking !== false &&
              !series[j].noSharedTooltip && series[j].singularTooltips !== true && series[j].tooltipPoints.length) {
            point = series[j].tooltipPoints[index];
            if (point && point.series) { // not a dummy point, #1544
              point._dist = Math.abs(index - point.clientX);
              distance = Math.min(distance, point._dist);
              points.push(point);
            }
          }
        }
        // remove furthest points
        i = points.length;
        while (i--) {
          if (points[i]._dist > distance) {
            points.splice(i, 1);
          }
        }
        // refresh the tooltip if necessary
        if (points.length && (points[0].clientX !== pointer.hoverX)) {
          tooltip.refresh(points, e);
          pointer.hoverX = points[0].clientX;
        }
      }

      // Separate tooltip and general mouse events
      followPointer = hoverSeries && hoverSeries.tooltipOptions.followPointer;
      if (hoverSeries && hoverSeries.tracker && !followPointer) { // #2584, #2830

        // get the point
        point = hoverSeries.tooltipPoints[index];

        // a new point is hovered, refresh the tooltip
        if (point && point !== hoverPoint) {

          // trigger the events
          point.onMouseOver(e);

        }
        
      } else if (tooltip && followPointer && !tooltip.isHidden) {
        anchor = tooltip.getAnchor([{}], e);
        tooltip.updatePosition({ plotX: anchor[0], plotY: anchor[1] });
      }

      // Start the event listener to pick up the tooltip 
      if (tooltip && !pointer._onDocumentMouseMove) {
        pointer._onDocumentMouseMove = function (e) {
          if (Highcharts.charts[chart.index]) {
            Highcharts.charts[chart.index].pointer.onDocumentMouseMove(e);
          }
        };
        Highcharts.addEvent(document, 'mousemove', pointer._onDocumentMouseMove);
      }

      // Draw independent crosshairs
      $.each(chart.axes, function (index) {
        chart.axes[index].drawCrosshair(e, Highcharts.pick(point, hoverPoint));
      });

      //added
      points && points.length>0 ? points[0].onMouseOver(e) : null;
    }
  },

  //对K线open == close时的一些特殊处理
  hackSeriesTypeCandlestickGetAttribs: function(e){
    Highcharts.seriesTypes.candlestick.prototype.getAttribs = function(){
      Highcharts.seriesTypes.ohlc.prototype.getAttribs.apply(this, arguments);
      var series = this,
        options = series.options,
        stateOptions = options.states,      
        upLineColor = options.upLineColor || options.lineColor,
        hoverStroke = stateOptions.hover.upLineColor || upLineColor, 
        selectStroke = stateOptions.select.upLineColor || upLineColor;

      // Add custom line color for points going up (close > open).
      // Fill is handled by OHLCSeries' getAttribs.
      Highcharts.each(series.points, function (point) {
        if (point.open == point.close){
          point.pointAttr[''].stroke = point.change_percent>0 ? '#e4462e' : '#4daf7b';
        }else if (point.open < point.close) {
          point.pointAttr[''].stroke = upLineColor;
          point.pointAttr.hover.stroke = hoverStroke;
          point.pointAttr.select.stroke = selectStroke;
        }
      });
    };

    Highcharts.seriesTypes.ohlc.prototype.getAttribs = function(){
      Highcharts.seriesTypes.column.prototype.getAttribs.apply(this, arguments);
      var series = this,
        options = series.options,
        stateOptions = options.states,
        upColor = options.upColor || series.color,
        seriesDownPointAttr = Highcharts.merge(series.pointAttr),
        upColorProp = series.upColorProp;

      seriesDownPointAttr[''][upColorProp] = upColor;
      seriesDownPointAttr.hover[upColorProp] = stateOptions.hover.upColor || upColor;
      seriesDownPointAttr.select[upColorProp] = stateOptions.select.upColor || upColor;

      Highcharts.each(series.points, function (point) {
        if (point.open == point.close){
          point.pointAttr[''][upColorProp] = point.change_percent>0 ? '#e4462e' : '#4daf7b';
        }else if (point.open < point.close) {
          point.pointAttr = seriesDownPointAttr;
        }
      });
    };

  }
}









//计算时分chart y轴坐标（之前算法，不强制0线中间）
  // calTickPositions: function(data_min, data_max){
  //   var min, max, tick_value, increment, positions = [];
  //   min = Math.min(this.minute_chart_compare_value, data_min);
  //   max = Math.max(this.minute_chart_compare_value, data_max);
  //   increment = this.adjustPositionIncrement(max, min);
  //   tick_value = this.adjustMinuteCompareValue(increment);
  //   for(var tick = AccMath.sub(tick_value, increment); tick + increment > min; tick = AccMath.sub(tick, increment)){
  //     positions.push(tick);
  //   }
  //   for(var tick = tick_value; tick - increment <= max; tick = AccMath.add(tick, increment)){
  //     positions.push(tick);
  //   }
  //   if (tick_value == positions.sort(function(a,b){return a-b;})[positions.length-1]) 
  //     positions.push(AccMath.add(tick_value, increment));

  //   return positions.sort(function(a,b){return a-b;});
  // },

  // adjustPositionIncrement: function(max, min){
  //   var multiples = [1, 2, 2.5, 5, 10], digit_num, multi_num;
  //   var increment = (max - min)/4;
  //   if (increment >= 1){
  //     digit_num = increment.toString().split(".")[0].length-1;
  //     multi_num = Math.pow(10, digit_num);
  //   }else{
  //     var right_string = increment.toString().split(".")[1] || "0";
  //     digit_num = right_string.length - parseInt(right_string).toString().length + 1;
  //     multi_num = Math.pow(0.1, digit_num);
  //   }
  //   for(index in multiples){
  //     var tmp_value = (multiples[index]*multi_num).round(digit_num+1)
  //     if (tmp_value >= increment){
  //       increment = tmp_value;
  //       break;
  //     }
  //   }
  //   return increment;
  // },

  // adjustMinuteCompareValue: function(tick_increment){
  //   var round_digit = tick_increment >= 0.1 ? 2 : 3;
  //   this.minute_round_digit = round_digit;
  //   this.minute_chart_compare_value = this.minute_chart_compare_value.round(round_digit);
  //   return this.minute_chart_compare_value;
  // },