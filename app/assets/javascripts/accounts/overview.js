$(function(){
  Overview.profitClickHandle();

  Overview.initNetWorthChart();

  Overview.loadPositions();
  
  Overview.loadOrders();
  
  Overview.loadNews();
})

//投资概览
var Overview = {
  loadPositions: function(){
    $.get("/accounts/" + gon.account_id + "/overview/positions");
  },

  loadOrders: function(){
    $.get("/accounts/" + gon.account_id + "/overview/orders");
  },

  loadNews: function(){
    $.get("/accounts/" + gon.account_id + "/overview/news");
  },

  initLoadMoreNews: function(){
    $("#j_news_more").on('click', function(){
      $(this).parent().remove();
      $.get("/accounts/" + gon.account_id + "/overview/news?page=" + $(this).attr('data-next-page'));
    })  
  },

  initNetWorthChart: function(){
    $.get('/ajax/accounts/' + gon.account_id + '/equities', {date: $('#j_profit_chart_tab .active').attr('data') }, function(datas) {
      $("#j_profit_chart_content").empty();
      Overview.setPerformanceChart("j_profit_chart_content", datas);
    })
  },

  initEarningsChart: function(){
    $.get('/ajax/accounts/' + gon.account_id + '/incomes', {date: $("#j_profit_chart_tab .active").attr('data') }, function(datas) {
      $("#j_profit_chart_content").empty();
      Overview.setPerformanceChart("j_profit_chart_content", datas);
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

  profitClickHandle: function(){
    $("#j_profit_chart_tab li").on('click', function(){
      $(this).siblings().removeClass("active").end().addClass("active");
      Overview.profitRequestHandle();
    })

    $(".j_profit_chart_type li").on('click', function(){
      $(this).siblings().removeClass("active").end().addClass("active");
      Overview.profitRequestHandle();
    })
  },

  profitRequestHandle: function(){
    var chartType = $('.j_profit_chart_type li.active').attr('data');
    if(chartType == 'net_worth'){
      Overview.initNetWorthChart();
    }else if(chartType == 'earnings'){
      Overview.initEarningsChart();
    }
  },

  sectorPieChart: function(sector_rates, sector_colors){
    Highcharts.getOptions().plotOptions.pie.colors = sector_colors,
    $('#j_sector_pie_chart').highcharts({
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
          // allowPointSelect: true,
          enableMouseTracking: false,
          innerSize: "70%",
          cursor: 'pointer',
          dataLabels: {
            enabled: false,
            //formatter: function(){
            //  if(this.percentage > 0){
            //    return '<b>' + this.point.name + '</b>:<br />' + Highcharts.numberFormat(this.percentage, 2) + '%';
            //  }
            //},
            format: '<b>{point.name}</b>:<br/> {point.percentage:.1f} %',
            style: {
              color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
            }
          }
        }
      },
      series: [{
        type: 'pie',
        name: 'Browser share',
        data: sector_rates
      }]
    });

    // 提示信息
    Overview.sectorPieChartPrompt(sector_rates, sector_colors);
  },
  
  sectorPieChartPrompt: function(sector_rates, sector_colors){
    $.each(sector_rates, function(index, element){
      var html = "<li><em style='background:" + sector_colors[index] + "'></em>" + (element.y * 100).toFixed(2) + "% <span>" + element.name + "</span></li>";
      $("#j_sector_pie_chart").next('.stock-in').append(html);
    })
  } 
  
}


function refreshCash(account_id, refresh_obj){
  if ($(refresh_obj).hasClass("load")) return;
  
  if (account_id != ""){
    $(refresh_obj).addClass("load");
    $.post("/accounts/"+account_id+"/refresh_cash", {}, function(response){
      $(refresh_obj).removeClass("load");
      window.location.reload();
    })
  }
}
