$(function(){
  StockChart.periodBtnClickHandle();
  StockCustomSearch.init();
  WeightSlider.initAllSliders();
  BasketSort.init();
  StockChart.draw();
  StockAdd.forbidenEnterEventInForm();

  // 删除所选股票
  $(document).on('click', '.j_remove_stock', function(){
    StockAdd.removeStock(this); 
  })

  //比重input
  $(document).on('change', '.customPercent input', function(){
    WeightSlider.weightInputChangeEvent(this);
  })

})

var StockAdd = {
  addToStockList: function(symbol_name, stock_area){
    var exist_stocks = $(".j_stock_symbol");
    if (exist_stocks.length >=10){
      $.alert({text: "最多添加10支股票！"});
    }else if (exist_stocks.length > 0 && stock_area != $(".j_stock_symbol:first").attr("area")){
      $.alert({text: "由于汇率转换的原因，目前美股、港股不能在一个主题投资里并存。"});
    }else{
      $.post("/ajax/baskets/search_add", {symbol_name:symbol_name});
    }
  },

  removeStock: function(del_obj){
    $(del_obj).closest('tr').remove();
    WeightSlider.adjustStocksWeight($(".scrollBar:last"));
    StockChart.draw();
  },

  checkWeightsIsValid: function(){
    var weight_sum = 0;
    $(".j_stock_weight").each(function(){
      weight_sum += parseFloat($(this).val()) * 1000;
    })
    if (weight_sum/1000 == 1){
      return true;
    }else{
      return false;
    }
  },

  //检查form
  checkForm: function(){
    if ($(".j_stock_symbol").length == 0){
      $.alert({text: "请添加至少一支股票！"});
      return false;
    }else if (!this.checkWeightsIsValid()){
      return false;
    }else{
      return true;
    }
  },
  // 禁止input回车提交
  forbidenEnterEventInForm: function(){
    $('.edit_basket_normal input').bind("keyup keypress", function(e) {
      var code = e.keyCode || e.which; 
      if (code == 13) { 
        $(this).trigger('change');
        e.preventDefault();
        return false;
      }
    });
  },

  refreshMinBuyMoney: function(){
    symbol_weights = StockChart.getStockWeights();
    $.post("/ajax/baskets/est_min_money", {symbol_weights: symbol_weights}, function(response){
      var currency_unit = $(".themeStocks tbody tr:first").attr("stock_area") == "hk" ? "HK$" : "$";
      $("#est_buy_min_money").text(currency_unit + accounting.formatMoney(response.money, ""));
    })
  }
}

// 股票排序
var BasketSort = {
  init: function(){
    $('.sortcolumn').each(function(){
      var th = $(this).parent(), thIndex = th.index();
      $(this).click(function(){
        sort_desc = BasketSort.setSortObjClass(this);

        $("#j_stocks_tbody").find('tr').sortElements(function(a, b){
          if(thIndex == 2){
            var aValue = $(a).find('.j_stock_weight').val();
            var bValue = $(b).find('.j_stock_weight').val();
          }else{
            var aValue = $(a).find('td, th').eq(thIndex).attr('data');
            var bValue = $(b).find('td, th').eq(thIndex).attr('data');
          }
          if ((parseFloat(aValue) || 0) > (parseFloat(bValue) || 0)){
            return (sort_desc ? -1 : 1);
          }else if((parseFloat(aValue) || 0) < (parseFloat(bValue) || 0)){
            return (sort_desc ? 1 : -1);
          }else{
            return -1;
          }
        });
        BasketSort.changeSortColumnStyle(thIndex);
      });
    });
  },

  //返回：true表示倒序
  setSortObjClass: function(sort_obj){
    var has_up_class = $(sort_obj).hasClass("sortup");
    var has_down_class = $(sort_obj).hasClass("sortdown");
    $(".sortcolumn").removeClass("sortup").removeClass("sortdown");
    if (!has_down_class){
      $(sort_obj).addClass("sortdown");
      return true;
    }else{
      $(sort_obj).addClass("sortup");
      return false;
    }
  },

  changeSortColumnStyle: function(index){
    $(".sortcell").removeClass("sortcell");
    $("#j_stocks_tbody tr").each(function(){
      $(this).find('td, th').eq(index).addClass("sortcell")
    })
  }

}

//
//slider methods
//

var WeightSlider = {

  initAllSliders: function(){
    $(".j_stock_symbol").each(function(){
      WeightSlider.initSlider($(this).parent().find('input:first').val());
    })
  },

  //init slider
  initSlider: function(slider_id){
    var slider_value = $("#slider_"+slider_id).next().val();

    $("#slider_" + slider_id).slider({
      range: "min",
      value: slider_value,
      min: 0,
      max: 100,
      step: 5,
      slide: function( event, ui ) {
        $(this).next().val(ui.value);
      },
      change: function( event, ui ) {
        $(this).parents('tr').find('.j_stock_weight').val($(this).slider("option", "value")*10/1000);
        var disabled = $(this).slider( "option", "disabled" );
        if (disabled != true){
          WeightSlider.lockSlider($(this));
          WeightSlider.adjustStocksWeight($(this));
          StockChart.draw();
        }
      }
    });
  },

  lockSlider: function(slider_obj){
    $(slider_obj).prev().removeClass('lockoff').addClass('lockon');
  },

  unlockSlider: function(slider_obj){
    $(slider_obj).prev().removeClass('lockon').addClass('lockoff');
  },

  toggleLockButton: function(button_obj){
    if ($(button_obj).hasClass('lockon')){
      this.unlockSlider($(button_obj).next());
    }else{
      this.lockSlider($(button_obj).next());
    }
  },

  adjustStocksWeight: function(slider_obj){
    var left_unlocked_weight = WeightSlider.leftUnlockedWeight();
    var unlocked = $(".lockoff");
    if (unlocked.length == 0 || (left_unlocked_weight < 0)){
      var slider_value = parseFloat($(slider_obj).next().val()) + left_unlocked_weight;
      WeightSlider.setValueToSlider(slider_obj, slider_value);
      unlocked.each(function(){ WeightSlider.setValueToSlider($(this).next(), 0); })
    }else if (unlocked.length > 0){
      var avg_value = parseInt((left_unlocked_weight * 10)/unlocked.length)/10;
      var last_unlocked_value = (left_unlocked_weight * 10 - avg_value * 10 * (unlocked.length - 1)) / 10;
      $(".lockoff:not(:last)").each(function(){ 
        WeightSlider.setValueToSlider($(this).next(), avg_value);
      })
      WeightSlider.setValueToSlider($(".lockoff:last").next(), last_unlocked_value);
    }
  },

  setValueToSlider: function(slider_obj, slider_value){
    $(slider_obj).slider("disable");
    $(slider_obj).slider( "option", "value", slider_value);
    $(slider_obj).slider("enable");
    $(slider_obj).next().val(slider_value);
  },

  leftUnlockedWeight: function(){
    return (1000 - WeightSlider.sumLockedWeight()*10)/10;
  },

  sumLockedWeight: function(){
    var locked_weight = 0;
    $(".lockon").each(function(){
      locked_weight += parseFloat($(this).nextAll('input').val()) * 10;
    })
    return locked_weight/10;
  },

  sumUnlockedWeight: function(){
    var unlocked_weight = 0;
    $(".lockoff").each(function(){
      unlocked_weight += parseFloat($(this).nextAll('input').val())*10;
    })
    return unlocked_weight/10;
  },

  weightInputChangeEvent: function(weight_input){
    //check value;
    var weight = $.trim($(weight_input).val());
    if (/^[0-9]+(\.[0-9]+)?/.test(weight)){
      $(weight_input).val(parseFloat(weight).toFixed(1));
    }else{
      $(weight_input).val(0);
    }
    $(weight_input).parents('tr').find('.j_stock_weight').val(parseFloat($(weight_input).val())*10/1000);
    WeightSlider.setValueToSlider($(weight_input).prev(), $(weight_input).val());
    WeightSlider.lockSlider($(weight_input).prev());
    WeightSlider.adjustStocksWeight($(weight_input).prev());
    StockChart.draw();
  }


}

//
// autoComplete
//

var StockCustomSearch = {
  init: function(){

    $('.searchgroup').searchBox({
      source: function(target){
        var $retBox = $(target).parent().find('ul.searchresult');
        var $request = $.trim($(target).val());

        $.get('/ajax/stocks/search', {term: $request}, function(data){
          if ($request == data.term){
            if (data.stocks.length > 0){
              $retBox.empty();
              $.each(data.stocks, function(index, item){
                var liHtml = "<li stock_id='" + item.stock_id + "' symbol='" +  item.symbol + "' area='" + item.area + "'>"; 
                liHtml += "<span class='code'>" + $.highlight(item.symbol, $request) + "</span>";
                liHtml += "<span class='name'>" + $.highlight(item.company_name, $request) + "</span>";
                liHtml += "</li>";
                $retBox.append(liHtml);
              })
              $retBox.fadeIn();
            }else{
              $retBox.empty().fadeOut(); 
            }
          }

        })
      },

      select: function(target){
        StockAdd.addToStockList(target.attr('symbol'), target.attr('area'));
      }

    });  

  }
}

//
// 定制图表相关
//
var StockChart = {
  draw: function(){
    $("#stock_index_chart").html("");
    var stock_weights = this.getStockWeights();
    var time_period = $("#j_time_period").find(".active").text();
    var basket_id = $('#j_time_period').attr('basket-id');
    $.post('/ajax/baskets/baskets_pre_index', {stock_weights:stock_weights, time_period:time_period, id: basket_id}, function(datas) {
      StockChart.displayChartInfos(datas.stocks, datas.baskets, datas.market_data, datas.market_name);

      $('#stock_index_chart').highcharts('StockChart', {
        global: {
          useUTC: false
        },

        chart: {
          height: 200,
          width: 673
        },

        rangeSelector : {
          enabled: false,
          inputEnabled: false
        },

        title: {
          text : null
        },

        credits: {
          enabled: false
        },

        xAxis: {
          dateTimeLabelFormats : {
            day: '%m/%d',
            week: '%m/%d',
            month: '%Y/%m',
            year: '%Y年'
          },
          showEmpty: false
        },

        yAxis: {
          opposite: false,
          offset: -15,
          labels: {
            align: 'left',
            formatter: function() {
              return calPrefix(this.value) + this.value +'%'; 
            }
          }
        },

        navigator: {
          enabled: false
        },

        scrollbar: {
          enabled: false
        },

        tooltip: {
          xDateFormat : "%Y-%m-%d",
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
              s += '<br/><span style="line-height: 25px;">' + point.series.name + '：<span style="color:' + StockChart.tooltipFontColor(point.y) + '">' + calPrefix(point.y) + point.y.toFixed(2) + ' %</span></span>';
            })
            return s;
          }
        },

        series: [{
          name : '定制前主题',
          data : datas.baskets,
          tooltip: {
            valueDecimals: 2
          },
          color: "#21ADE0",
          fillColor : {
            linearGradient : {
              x1: 0, 
              y1: 0, 
              x2: 0, 
              y2: 1
            },
            stops : [[0, "#ACD6FF"], [1, '#FFFFFF']]
          }
        }, 
        {
          name: '定制后主题',
          data: datas.stocks,
          tooltip: {
            valueDecimals: 2
          },
          color: 'red'
        },
        {
          name : datas.market_name,
          data : datas.market_data,
          tooltip: {
            valueDecimals: 2
          },
          color: "#7DCD6D",
          fillColor: 'white'
        }]
      });

    });

    StockAdd.refreshMinBuyMoney();
  },

  //选择股票页面获取所选股票比重
  getStockWeights: function(){
    var stock_weights = {};
    $(".j_stock_weight").each(function(){
      var symbol_name = $.trim($(this).parents('tr').find('td:first').text());
      stock_weights[symbol_name] = parseFloat($(this).val());
    })
    return stock_weights;
  },

  //charts下面文字显示
  displayChartInfos: function(customed, original, market_data, market_name){
    // 定制后回报
    if(customed.length >= 1){
      var _customed_percent = customed.slice(-1)[0][1].toFixed(2);
      $('#j_customed_notice').find('span').html(StockChart.returnRateHtml(_customed_percent)).end().show();
    }else{
      $("#j_customed_notice").hide();
    }

    // 定制前回报
    var _original_percent = original.slice(-1)[0][1].toFixed(2);
    $('#j_original_notice > span').html(StockChart.returnRateHtml(_original_percent));
    
    // SP500等等
    $("#j_indexes_notice").find('em').text(market_name);
    var _index_percent = market_data.slice(-1)[0][1].toFixed(2);
    $('#j_indexes_notice > span').html(StockChart.returnRateHtml(_index_percent));
  },

  returnRateHtml: function(change_percent){
    var html = $("#j_time_period").find(".active").text() + '回报 ';
    html += '<em class="' + this.emClass(change_percent) + '">' + change_percent + '%</em>';
    return html;
  },

  emClass: function(change_percent){
    return change_percent >= 0 ? 'plus' : 'mins';
  },

  periodBtnClickHandle: function(){
    $("#j_time_period > li").on('click', function(){
      $(this).siblings().removeClass('active').end().addClass('active');
      StockChart.draw();
    })
  },

  tooltipFontColor: function(value){
    return value>=0 ? "red" : "green";
  }

}

