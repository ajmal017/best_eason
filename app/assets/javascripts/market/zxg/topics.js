$(function(){
  var $content = $('.content');
  if ($content.height() > 140){
    $content.addClass('overload');
    $('<span class="pulldown">展开</span><span class="rollup">收起</span>').click(function(){
      $content.toggleClass('overload');
			QQFinance_SetHeight(document.documentElement.scrollHeight);
    }).appendTo($content);
  }

  requestStockPrices();

  $(document).on("mouseenter", ".stocks .list a", function () {
    var stock_id = $(this).attr("stock-id"),
        stockChart = $(this).find(".chart");
    setStockChart(stockChart, stock_chart_datas[stock_id]);
  })

  $('a[href]').each(function(){
    this.href+=((this.href.indexOf('?')<0)?'?':'&')+'from=zxg_topic';
  });
})

function requestStockPrices(){
  var stock_ids = [];
  $(".stocks .list a").each(function(){
    stock_ids.push($(this).attr("stock-id"));
  })
  $.get("/ajax/stocks/prices", {stock_ids: stock_ids}, function(response){
    $.each(response, function(index){
      var stock_id = response[index][0],
          price = response[index][1],
          price_changed = response[index][2],
          em_class = price_changed>=0 ? "plus" : "mins",
          em_operator = price_changed>=0 ? "+" : "",
          price_span = $(".stocks .list a[stock-id=" + stock_id + "] .price");
      price_span.prepend(price).prepend(price_span.attr("data-unit"));
      price_span.find("em").text(em_operator + price_changed + "%").addClass(em_class);
    })
  })
}

function setStockChart(obj, chart_datas) {
  $(obj).highcharts({
        global: {
          timezoneOffset: -480,
          useUTC: true
        },
        chart: {
          marginBottom: 15,
          marginTop: 17,
          marginLeft: 10,
          marginRight: 10,
          backgroundColor: '#4183c4',
          style: {
            fontFamily: '"Helvetica Neue", Arial, "Microsoft YaHei"',
            fontSize: '12px'
          }
        },
        title: {
            text: null,
        },
        labels: {
          items: [{
            html: "<span>" + chart_datas.symbol + "</span>",
            style: {
                left: '10px',
                top: '0px',
                color: 'rgba(95, 155, 212, .9)',
                font: "font-weight: bold;font-size:14px;"
            }
          }]
        },
        xAxis: {
          categories: chart_datas.date,
          lineColor: 'rgba(255, 255, 255, .2)',
          tickColor: 'rgba(255, 255, 255, .4)',
          tickLength: 5,
          labels: {
            enabled: false
          }
        },
        credits: {
          enabled: false
        },
        yAxis: {
            gridLineWidth: 0
        },
        tooltip: {
          crosshairs: [
            {
                width: 1,
                color: 'rgba(56, 58, 76, .5)'
            }, 
            false
          ],
          backgroundColor: 'rgba(255, 255, 255, 0)',
          borderWidth: 0,
          shadow: false,
          style: {
            color: '#fff',
            fontSize: '12px',
            padding: '0px',
            margin: '0px'
          },
          formatter: function(){
            return chart_datas.unit + this.y;
          }
        },
        legend: {
          enabled: false
        },
        plotOptions: {
            series: {
                marker: {
                  radius: 2,
                  states: {
                        hover: {
                          radius: 4.5,
                          halo: false,
                          lineWidth: 0,
                          lineWidthPlus: 0
                        }
                    }
                },
                states: {
                  hover: {
                    halo: false,
                    lineWidth: 1,
                    lineWidthPlus: 0
                  }
                }
            }
        },
        series: [{
          data: chart_datas.datas,
          lineWidth: 1,
          color: 'rgba(255, 255, 255, 0.85)'
        }]
    });
}