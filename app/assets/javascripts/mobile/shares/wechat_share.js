//= require jquery
//= require jquery.timeago
//= require jquery.timeago.settings
//= require highstock

$(function(){

  // function loadChart(basket_id){
  //    $.get("/mobile/baskets/"+basket_id+"/chart_datas", function(datas) {
  //       setBasketChart(datas);
  //       drawRatio(datas.simulated, datas.ratio);
  //    })
  // }

  // function drawRatio(simulated, ratio){
  //   str = "一月回报";
  //   if(simulated){
  //   // if(true){
  //     str += "(预估的)";
  //   }
  //   str += ("<br/><span>"+ratio+"</span>");
  //   $("#j_basket_ratio").html(str);
  // }

  // function setBasketChart(chart_datas) {
  //   $("#j_basket_chart").highcharts({
  //         global: {
  //           useUTC: true
  //         },
  //         chart: {

  //           marginBottom: 50,
  //           marginTop: 50,
  //           marginLeft: 100,
  //           marginRight: 100,
  //           backgroundColor: 'none',
  //           style: {
  //             fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
  //             fontSize: '12px'
  //           }
  //         },
  //         title: {
  //             text: null,
  //         },
  //         xAxis: {
  //           type: 'datetime',
  //           lineColor: 'rgba(255, 255, 255, .2)',
  //           tickColor: 'rgba(255, 255, 255, .4)',
  //           lineWidth: 0,
  //           tickLength: 0,
  //           showFirstLabel: false,
  //           startOnTick: true,
  //           labels: {
  //             formatter: function(){
  //               return Highcharts.dateFormat('%m-%d', this.value);
  //             },
  //             style: {
  //               color: 'rgba(255, 255, 255, 0.8)',
  //               fontSize: '18px'
  //             },
  //             y: 0
  //           }
  //         },
  //         credits: {
  //           enabled: false
  //         },
  //         yAxis: {
  //             gridLineWidth: 0,
  //             offset: 0,
  //             title: {
  //               text: null
  //             },
  //             labels: {
  //               enabled: true,
  //               format: "{value}%",
  //               style: {
  //                 color: 'rgba(255, 255, 255, 0.8)',
  //                 fontSize: '18px'
  //               }
  //             }
  //         },
  //         tooltip: {
  //           enabled: false
  //         },
  //         legend: {
  //           enabled: false
  //         },
  //         series: [{
  //           data: chart_datas.market,
  //           lineWidth: 4,
  //           color: 'rgba(255, 255, 255, 1)',
  //           animation: false,
  //           marker: {
  //             symbol: 'circle'
  //           }
  //         },
  //         {
  //           data: chart_datas.basket,
  //           lineWidth: 4,
  //           color: '#252886',
  //           symbol: 'circle',
  //           animation: false,
  //           marker: {
  //             symbol: 'circle'
  //           }
  //         }]
  //     });
  // }

  // loadChart(window.basket_id);

});