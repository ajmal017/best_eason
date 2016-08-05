var EasyNetWorth = {

  initChart: function(){
    $.get('/ajax/users/easy_networth_chart', function(datas) {
      EasyNetWorth.setChart(datas);
      if(datas.ratio)
        $("#j_easy_networth_ratio").html(Math.abs(datas.ratio)+"<em>%</em>").attr("class", datas.ratio >= 0 ? 'plus' : 'mins');
    })
  },

  setChart: function(chart_datas){
    var tick_interval;
    var datas_length = chart_datas.datas.length;
    if (datas_length >= 20){
      tick_interval = 5*24*3600*1000;
    }else if (datas_length >= 12){
      tick_interval = 4*24*3600*1000;
    }else if (datas_length > 6){
      tick_interval = 2*24*3600*1000;
    }else{
      tick_interval = null;
    }

    $("#j_easy_networth_chart").highcharts('StockChart', {
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
        gridLineWidth: 0, 
        lineWidth: 0,
        minorGridLineWidth: 0,
        lineColor: 'transparent',
        // startOnTick: true,
        minorTickLength: 0,
        tickLength: 0,
        minTickInterval: tick_interval,
        // showLastLabel: false,
        labels: {
            // enabled: true,
            formatter: function(){
              return Highcharts.dateFormat('%m-%d', this.value);
            },
            style: {
              color: 'white'
            },
            align: 'left',
            overflow: "justify",
            x: 0,
            y: 11
        },
        title: {
            text: null
        }
      },
      yAxis: {
        gridLineWidth: 0, 
        lineWidth: 0,
        minorGridLineWidth: 0,
        lineColor: 'transparent',
        minorTickLength: 0,
        tickLength: 0,
        tickPixelInterval: 200,
        labels: {
            enabled: false
        },
        title: {
            text: null
        }
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
          margin: 0
        },
        valueDecimals: 2,
        headerFormat: '<div class="elastic-layer"><ol>',
        pointFormat: '<li>'+chart_datas.unit+'{point.y}</li>',
        footerFormat: '</ol></div>'
      },
      chart: {
          plotBackgroundImage: '/images/v2/chart/chart_back.png',
          backgroundColor: 'rgba(0,0,0,0)',
          padding: 0,
          margin: 0,
          spacing: [0,0,0,0],
          marginBottom: 12
        },
      series: [
        {
          threshold: null,
          name : null,
          data : chart_datas.datas,
          tooltip: {
            valueDecimals: 2
          },
          type: 'area',
          fillColor : "rgba(66, 118, 166, 0.5)", 
          color: "rgba(100, 160, 215, 0.5)"
          
        }]
    });
  }

 

}