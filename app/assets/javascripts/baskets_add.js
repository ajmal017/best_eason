$(function(){
  $(".createSearch input").val("");
  $(".createSearch input").focus();

  StockAutoComplete.init();
  
  //stock charts: 选择时间段
  StockChart.periodBtnClickHandle();
})

//
// basket add methods
//
var currency_units = {"hk": "HK$", "cn": "￥", "us": "$"};

var BasketAdd = {
  join_contest: false,

  checkBasketStocksValid: function(basket_stocks_params){
    var stock_group = StockGroup.publish();
    if (!stock_group) return false;
    
    var stocks_infos = StockGroup.report().stocks,
        stock_count_of_gte_1_percent = 0;
    $.each(stocks_infos, function(index){
      if (stocks_infos[index].weight >= 0.01) stock_count_of_gte_1_percent += 1;
    })

    if (stock_count_of_gte_1_percent < 1){
      // CaishuoDialog.open({theme:'tip',content:'创建组合，应包含至少一只仓位大于1%的股票！'});
      return false;
    }else if(stocks_infos.size > 10){
      // CaishuoDialog.open({theme:'tip',content:'最多添加10只股票'});
      return false;
    }
    return true;
  },

  getBasketStocksParams: function(){
    var stocks_infos = StockGroup.report().stocks,
        basket_stocks_attributes = {},
        params = {};
    params["contest"] = BasketAdd.join_contest;
    $.each(stocks_infos, function(index){
      var stock_infos = stocks_infos[index];
      basket_stocks_attributes[index] = {id: stock_infos.basket_stock_id, stock_id: stock_infos.sid, weight: stock_infos.weight};
    })
    params["basket_stocks_attributes"] = basket_stocks_attributes;
    return params;
  },

  updateBasket: function(){
    if (this.checkBasketStocksValid() == true){
      this.forbiddenSubmitBtn();
      $.post("/baskets/"+_basket_id+"/update_stocks", {basket: BasketAdd.getBasketStocksParams(), _method: "put"}, function(response){
        if (response.status == true){
          window.location.href = "/baskets/"+_basket_id+"/base";
        }else{
          BasketAdd.enabledSubmitBtn();
        }
      });
    }
  },

  forbiddenSubmitBtn: function(){
    $("#btn_submit").attr("disabled", "disabled");
  },

  enabledSubmitBtn: function(){
    $("#btn_submit").removeAttr("disabled");
  },

  ContestActionHandler: function(come_from, is_contest_basket, exist_stock_ids){
    //从编辑等入口进入组合第一步时没有come_from参数，不用进行相关的判断
    if (come_from == "" || !come_from) return;

    var come_from_contest_page = come_from == "contest";

    if (_user_contest_basket_id && (_user_contest_basket_id != _basket_id) & come_from_contest_page){
      return CaishuoDialog.open({theme:'confirm',title:'A股大赛提示',content:'只能创建一支A股大赛组合，此组合会被当做普通组合处理，如需调整大赛组合请编辑大赛组合！'});
    }

    if (come_from_contest_page){
      BasketAdd.join_contest = true;
      if (!is_contest_basket && exist_stock_ids.length>0){
        CaishuoDialog.open({theme:'confirm',title:'A股大赛提示',content:'您有一个未完成的组合在草稿箱里，想继续编辑它么？<br/>注：A股大赛只能购买沪深A股！', callback:function(){
          BasketAdd.clearAllStocks();
        }, btntext:{confirm:'清空', cancel:'继续'}, btnclass:{confirm:'b_btn dialog_btn_c', cancel:'b_btn dialog_btn_y'} });
      }
    }else{
      BasketAdd.join_contest = false;
      if (is_contest_basket && exist_stock_ids.length>0){
        CaishuoDialog.open({theme:'confirm',title:'提示',content:'您有一个未完成的组合在草稿箱里，想继续编辑它么？', callback:function(){
          BasketAdd.clearAllStocks();
        }, btntext:{confirm:'清空', cancel:'继续'}, btnclass:{confirm:'b_btn dialog_btn_c', cancel:'b_btn dialog_btn_y'} });
      }
    }
  },

  clearAllStocks: function(){
    $(".j_remove_stock").each(function(){
      StockGroup.earse($(this));
    })
  }

}

//
// 股票搜索自动提示
//
var StockAutoComplete = {
  autocompte_result_active: false,

  init: function(){
    this.inputKeyupHandle();
    this.inputFocusHandle();
    this.inputBlurHandle();
    this.stocksMouseenterHandle();
    this.stocksMouseleaveHandle();
    this.stocksClickHandle();
  },

  inputKeyupHandle: function(){
    //用户输入推荐，及对上下enter键的处理
    $("#searchInput").on("keyup", function(event){
      if (event.which == "40"){
        StockAutoComplete.moveDownList(); //down
        return false;
      }else if (event.which == "38"){
        StockAutoComplete.moveUpList(); //up
        return false;
      }else if (event.which == "13"){
        StockAutoComplete.selectStockAtList(); //enter
        return false;
      }else{
        StockAutoComplete.autocomplete();
      }
    })
  },

  inputFocusHandle: function(){
    $("#searchInput").on("focus", function(){
      StockAutoComplete.autocomplete();
    })
  },

  inputBlurHandle: function(){
    $("#searchInput").on("blur", function(){
      if (!StockAutoComplete.autocompte_result_active){
        StockAutoComplete.hideStocks();
      }
    })
  },

  stocksMouseenterHandle: function(){
    $(document).on("mouseenter", ".ac-add-stack-item", function(){
      StockAutoComplete.autocompte_result_active = true;
      $(this).siblings().removeClass("active");
      $(this).addClass("active");
    })
  },

  stocksMouseleaveHandle: function(){
    $(document).on("mouseleave", ".ac-add-stack-item", function(){
      StockAutoComplete.autocompte_result_active = false;
    })
  },

  stocksClickHandle: function(stock_li){
    //ac点击列表添加
    $("#searchResult").on('click', '.ac-add-stack-item', function(){
      StockAutoComplete.addToStockList($(this));
      StockAutoComplete.hideStocks();
      StockAutoComplete.clearUserInput();
    })
  },

  //自动提示
  autocomplete: function(){
    var user_input = $.trim($("#searchInput").val()),
        market = BasketAdd.join_contest ? "cn" : StockGroup.report().market; //A股大赛只能选A股
    if (user_input.length == 0){
      this.hideStocks();
      return false;
    }
    $.getJSON("/ajax/stocks/search", {term:user_input, show_desc: true, market: market}, function(datas){
      if ($.trim($("#searchInput").val()) == datas.term){
        if (datas.stocks.length > 0){
          StockAutoComplete.displayStocks(datas.stocks, datas.term);
        }else{
          StockAutoComplete.noResult();
        }
      }
    })
  },

  //呈现提示层
  displayStocks: function(stocks, search_term){
    $("#searchResult li").remove();
    $.each(stocks, function(index){
      var item_html = '<li class="ac-add-stack-item" symbol="' + stocks[index].symbol + '" area="' + stocks[index].area + '">';
      item_html += '<span class="code">' + StockAutoComplete.highlightUserInput(stocks[index].symbol, search_term) + '</span>';
      item_html += '<span class="name">' + StockAutoComplete.highlightUserInput(stocks[index].company_name, search_term) + '</span>';
      item_html += '<span>' + stocks[index].desc + '</span></li>';
      $("#searchResult").append(item_html);
    })
    $("#searchResult").fadeIn();
    this.activeFirstItem();
  },

  activeFirstItem: function(){
    $("#searchResult li:first").addClass("active").siblings().removeClass("active");
  },

  //隐藏提示层
  hideStocks: function(){
    $("#searchResult").fadeOut();
    if ($.trim($("#searchInput").val()) == ""){
      $("#searchResult li").remove();
    }
  },

  noResult: function(){
    $("#searchResult li").remove();
    var item_html = "<li>当前股票市场没有对应记录，请尝试其它搜索词！</li>"
    $("#searchResult").append(item_html).fadeIn();
  },

  clearUserInput: function(){
    $("#searchInput").val("");
  },

  highlightUserInput: function(str, highlight_str){
    var regexp = new RegExp(highlight_str, "i");
    return str.replace(regexp, "<em>" + highlight_str.toUpperCase() + "</em>");
  },

  //input 按向下键盘
  moveDownList: function(){
    var active_stock = $("#searchResult li").filter(".active");
    if (active_stock.length == 0 || active_stock.next().length == 0){
      $("#searchResult li").filter(":first").addClass("active");
    }else{
      active_stock.next().addClass("active");
    }
    active_stock.removeClass("active");
  },

  //input 按向上键盘
  moveUpList: function(){
    var active_stock = $("#searchResult li").filter(".active");
    if (active_stock.length == 0 || active_stock.prev().length == 0){
      $("#searchResult li").filter(":last").addClass("active");
    }else{
      active_stock.prev().addClass("active");
    }
    active_stock.removeClass("active");
  },

  //input 按enter键，选择active的stock到list
  selectStockAtList: function(){
    $("#searchResult li").filter(".active").trigger("click");
  },

  //添加股票到列表
  addToStockList: function(stock_ac_item){
    var symbol_name = $(stock_ac_item).attr("symbol");
    $.post("/baskets/search_add", {symbol_name:symbol_name}, function(response){
      StockGroup.append(response);
    });
  }

}


//
// 图表相关
//
var StockChart = {
  draw: function(){
    $("#stock_index_chart").html("");
    stock_weights = this.getStockWeights();
    var time_period = $(".themeData > ol").find(".active").text();

    $.post('/ajax/baskets/stocks_pre_index', {stock_weights:stock_weights, time_period:time_period}, function(datas) {
      StockChart.displayChartInfos(datas.stocks, datas.market_data, datas.market_name);

      $('#stock_index_chart').highcharts('StockChart', {
        global: {
          useUTC: false
        },
        chart: {
          style: {
            fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
            fontSize: '12px'
          },
          panning: false
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
          opposite: true,
          offset: -15,
          labels: {
            align: 'right',
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
          name : '投资主题',
          data : datas.stocks,
          tooltip: {
            valueDecimals: 2
          },
          type: 'line',
          connectNulls: true,
          color: "#87bdee"
        }, 
        {
          name : datas.market_name,
          data : datas.market_data,
          tooltip: {
            valueDecimals: 2
          },
          color: "#7DCD6D"
        }]
      });
      
    });

    // BasketAdd.refreshMinBuyMoney();
  },

  //选择股票页面获取所选股票比重
  getStockWeights: function(){
    var stock_weights = {"cash.cash": StockGroup.report().cash}, 
        stocks = StockGroup.report().stocks;
    $.each(stocks, function(index){
      stock_weights[stocks[index].symbol] = stocks[index].weight;
    })
    return stock_weights;
  },

  //charts下面文字显示
  displayChartInfos: function(stocks_data, market_data, market_name){
    if (stocks_data.length > 0){
      var motif_change = stocks_data[stocks_data.length-1][1].toFixed(2);
      $(".themeData .motif").html(this.returnRateHtml(motif_change));
    }
    if (market_data.length > 0){
      var sp500_change = market_data[market_data.length-1][1].toFixed(2);
      $(".themeData .sp500").html(this.returnRateHtml(sp500_change));
    }
    $("#market_line_name").text(market_name);
  },

  returnRateHtml: function(change_percent){
    var time_period = $(".themeData > ol").find(".active").text();
    var html = time_period + '回报 ';
    if (change_percent >= 0 ){
      html += '<em class="plus">+' + change_percent + '%</em>';
    }else{
      html += '<em class="mins">' + change_percent + '%</em>';
    }
    return html;
  },

  periodBtnClickHandle: function(){
    $(".themeData > ol li").on("click", function(){
      $(this).siblings().removeClass("active");
      $(this).addClass("active");
      StockChart.draw();
    })
  },

  tooltipFontColor: function(value){
    return value>=0 ? "red" : "green";
  }
};



