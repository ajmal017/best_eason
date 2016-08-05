function getPageByPageLink(page_link_obj){
  var page;
  var current_page = parseInt($(page_link_obj).parent().find('.current').text());
  
  if ($(page_link_obj).hasClass("previous_page")){
    page = parseInt(current_page) - 1;
  } else if ($(page_link_obj).hasClass("next_page")){
    page = parseInt(current_page) + 1;
  }else{
    page = $(page_link_obj).text();
  }

  return page;
}



//投资概览
var Investment = {

  initCircleChart: function(){
    $.get('/ajax/users/investment_percent', {}, function(datas) {
      Investment.setCircleChart(datas.basket, datas.stock, datas.cash);
    })
  },

  setCircleChart: function(basket_percent, stock_percent, cash_percent){
    $("#investment_circle_chart").highcharts({
      chart: {
          plotBackgroundColor: null,
          plotBorderWidth: null,
          plotShadow: false,
          marginBottom: 0,
          marginTop: 0,
          marginLeft: 0,
          marginRight: 0,
          style: {
            fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
            fontSize: '12px'
          }
      },
      credits: {
        enabled: false
      },
      title: {
          text: null
      },
      tooltip: {
        pointFormat: '<b>{point.percentage:.1f}%</b>'
      },
      plotOptions: {
          pie: {
              allowPointSelect: false,
              cursor: 'pointer',
              size: 162,
              dataLabels: {
                  enabled: false,
                  color: '#000000',
                  connectorColor: '#000000',
                  format: '{point.percentage:.1f} %',
                  distance: -30,
                  format: '{y}%',
                  color: 'white',
                  style: {
                      fontWeight: 'bold',
                      fontSize: '16px'
                  }
              }
          }
      },
      series: [{
          type: 'pie',
          name: '投资情况',
          data: [
              {name:'主题投资', y:basket_percent, color: '#64a0d7'},
              {name:'个股投资', y:stock_percent, color: '#a3c8ea'},
              {name:'现金', y:cash_percent, color: '#383a4c'}
          ]
      }]
    })
  },

  initNetWorthChart: function(){
    $.get('/ajax/users/networth_chart', {date: $('#net_worth_periods .active').attr('data') }, function(datas) {
      Investment.setPerformanceChart("net_worth_chart", datas);
    })
  },

  initEarningsChart: function(){
    $.get('/ajax/users/profit_datas', {date: $("#j_profit_periods .active").attr('data') }, function(datas) {
      Investment.setPerformanceChart("j_profits_chart", datas);
    })
  },

  setPerformanceChart: function(chart_id, chart_datas){
    var y_floor = this.minYValueBy(chart_datas.datas);
    $('#' + chart_id).highcharts('StockChart', {
      global : {
        useUTC: false
      },
      chart: {
        style: {
          fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
          fontSize: '12px'
        }
      },
      rangeSelector : {
        enabled: false
      },
      title: {
        text : null
      },
      credits: {
        enabled: false
      },
      xAxis: {
        gridLineWidth: 1,
        gridLineColor: '#F0F0F0',
        dateTimeLabelFormats : {
          day: '%m-%d',
          week: '%m-%d',
          month: '%m月',
          year: '%Y年'
        },
        minRange: 24 * 3600 * 1000
      },
      yAxis: {
        gridLineColor: '#F0F0F0',
        opposite: false,
        offset: -15,
        labels: {
          align: 'left',
          formatter: function() {
            return chart_datas.unit + Highcharts.numberFormat(this.value, 0, '', ','); 
          }
        },
        min: y_floor,
        startOnTick: false,
        endOnTick: false,
        showLastLabel: true,
        showFirstLabel: true
      },
      navigator: {
        enabled: false
      },
      scrollbar: {
        enabled: false
      },
      tooltip: {
        xDateFormat: "%Y-%m-%d",
        shared: true,
        useHTML: true,
        style: {
          padding: 0,
          margin: 0,
          border: 0
        },
        shape: 'square',
        shadow: false,
        borderWidth: 0,
        valueDecimals: 2,
        headerFormat: '<div class="elastic-layer"><ol><li>{point.key}</li>',
        pointFormat: '<li>'+chart_datas.unit+'{point.y}</li>',
        footerFormat: '</ol></div>'
      },
      plotOptions: {
        area: {
          threshold: null,
          tooltip: {
            valueDecimals: 2
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
          color: "#87bdee"
        }
      },
      series: [
        {
          name : '',
          data : chart_datas.datas,
          type: 'area',
        }]
    });
  },

  minYValueBy: function(chart_datas){
    var min = chart_datas[0] ? chart_datas[0][1] : 0;
    $.each(chart_datas, function(index){
      min = Math.min(min, chart_datas[index][1])
    })
  },

  netWorthPeriodsHandle: function(){
    $("#net_worth_periods li").on("click", function(){
      $(this).siblings().removeClass("active").end().addClass("active");
      Investment.initNetWorthChart();
    })
  },

  earningsPeriodsHandle: function(){
    $("#j_profit_periods li").on("click", function(){
      $(this).siblings().removeClass("active").end().addClass("active");
      Investment.initEarningsChart();
    })
  }

}


//
//持仓明细
// var Position = {
//   stockBuySellBtnClickHandle: function(){
//     $('a.stock_buy').on("click", function(){
//       var stock_id = $(this).parent().attr("stock_id");
//       window.open('/stocks/' + stock_id + "?trade=buy");
//       // Position.loadTradeContent("buy", this);
//     });

//     $('a.stock_sell').on("click", function(){
//       var stock_id = $(this).parent().attr("stock_id");
//       window.open('/stocks/' + stock_id + "?trade=sell");
//       // Position.loadTradeContent("sell", this);
//     });
//   },

//   loadTradeContent: function(trade_type, btn_obj){
//     $("#stock_trade_content").html("loading......");
//     Position.showFloat();
//     stock_id = $(btn_obj).parent().attr("stock_id");
//     $.get("/ajax/users/trade_stock?type=" + trade_type, {stock_id: stock_id}, function(response){
//       eval(response);
//     })
//   },

//   showFloat: function(){
//     $('#FloatWindow').fadeIn();
//     $('#FloatWindow .FloatContent').slideDown();
//     $('body').addClass('fixed');
//   },

//   hideFloat: function(){
//     $('#FloatWindow').fadeOut();
//     $('#FloatWindow .FloatContent').slideUp();
//     $('body').removeClass('fixed');
//   }
// }


var OrderManage = {
  in_process_ids: '',

	reloadOrders: function () {
    if (OrderManage.in_process_ids != ""){
      $.get("/users/order_list", {order_ids: OrderManage.in_process_ids}, function(){})
    }
	},
	
	init: function () {
		setInterval("OrderManage.reloadOrders();", 3000);
		
		$(document).on('click', '.j_cancel_order', function() {
		  var order_id = $(this).attr("order_id");
			var order = $(this);
		  CaishuoConfirm('您确定要取消吗？', function(){
				order.hide(100, function(){$(this).remove();});
		    $.post("/ajax/orders/" + order_id + "/cancel", {}, function (data) {
		    	if(data.status){
		    		CaishuoAlert('已将取消指令成功发出');
						$("#order_" + order.attr("order_id") + " .order_details li:last em.light_blue").text('取消中：请稍候');
		    	}else{
		    		CaishuoAlert('对不起，订单已完成，无法取消');
		    	}
				});
        return true;
		  })
		})

    $(".order_table li").on("click", function(){
      $(this).siblings().removeClass("cur");
      $(this).addClass("cur");
    })
		
		
	}
}



var HistoryOrders = {

  showOrderDetails: function(order_id){
    HistoryOrders.showLoading();
    $.get("/ajax/orders/" + order_id + "/details", {})
  },

  showLoading: function(){
    $("#floatWindow").html('<div class="floatcentent"><div class="floatcentent"><h5>加载中......</h5></div></div>');
    $("#floatWindow").show();
  },

  hideFloatWindow: function(){
    $("#floatWindow").hide();
  },
	
	addAnchorToPageLinks: function() {
		$(".pageNav a").each(function () {
			$(this).attr("href", $(this).attr("href") + "#history_orders");
		})
	}
}
