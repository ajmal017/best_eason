//= require jquery
//= require highstock


$(function(){

  function loadChart(basket_id){
    $.get("/mobile/shares/stocks/" + stock_id + "/graph_datas", {}, function(data){
      setBasketChart(data);
    })
  }

  function setBasketChart(chart_datas) {
    var ydata = []
    var eles = chart_datas.one_day_minutes
    for (var index in eles) {
      ydata.push(eles[index][1])
    }
    var plotLineValue = chart_datas.previous_close
    if(chart_datas.change_from_previous_close.match(/-/)){
      var color = '#2fb959'
    }else{
      var color = '#fc5152'
    }

    $("#stock_chart").highcharts({
          chart: {
            height: 200,
            width: 650,
          },
          title: {
              text: null,
          },
          xAxis: {
            type: 'datetime',
            lineWidth: 0,
            tickLength: 0,
            showFirstLabel: false,
            startOnTick: true,
            labels: {
              enabled: false
            }
          },
          credits: {
            enabled: false
          },
          yAxis: {
            gridLineWidth: 0,
            offset: 0,
            title: {
              text: null
            },
            labels: {
              enabled: false
            },
            plotLines:[{
                color: '#eeeeee',
                dashStyle: 'solid',
                value: plotLineValue,
                width: 5,
            }]
          },
          plotOptions: {
            series: {
              marker: {
                radius: 0,
                states: {
                  hover: {
                    radius: 3,
                    halo: false,
                    lineWidthPlus: 0
                  }
                }
              },
              states: {
                hover: {
                  halo: false,
                  lineWidthPlus: 0
                }
              }
            }
          },
          tooltip: {
            enabled: true
          },
          legend: {
            enabled: false
          },
          series: [{
            data: ydata,
            lineWidth: 3,
            color: color,
            animation: false,
            marker: {
              symbol: 'circle'
            }
          }]
      });
  }

  loadChart(window.basket_id);

});