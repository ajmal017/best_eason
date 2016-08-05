$(function(){
  
  $(".j_stocks_addmore").click(function () {
    var page = getCurrentPage() + 1;
    searchStocks(page, false, false, false);
  })
  
  $(document).on("mouseenter", ".j_stocks_search a", function () {
    if($(this).find(".stockchart").attr("request-already") != "true"){
      var stock_id = $(this).attr("stock-id");
      var stockChart = $(this).find(".stockchart");
      $.get('/ajax/stocks/' + stock_id + '/chart', function(datas) {
        setStockChart(stockChart, datas);
        stockChart.attr("request-already", "true");
      })
    }
  })

  //history back go
  window.onpopstate = function(event) {
    if (event.state && event.state["search"]){
      setSearchConditions(event.state);
      searchStocks(1, true, false, false);
    }
  };

  $('.searchmenu dt').click(function(){
    if ($(this).parent().hasClass('selected')) return;
    $(this).parent().toggleClass('active').siblings('dl').not('.selected').removeClass('active');
    caishuo.adjustFooter();
  });

  //.attr('href','javascript:void(0)')
  $('.searchmenu dl a').click(function(){
    if ($(this).hasClass("disabled")) return false;
    $(this).addClass('active').siblings().removeClass("active");
    $(this).closest('dl').addClass('selected').siblings('dl').not('.selected').removeClass('active');
    $('.searchmenu h2 del').show();
    $(".j_stocks_search").empty();
    adjustSearchMenus();
    searchStocks(1, true, false, true);
    return false;
    //caishuo.adjustFooter();
  });


  $('.j_filter_order .sortcolumn').click(function(){
    $(this).siblings().removeClass('sortup').removeClass('sortdown');
    if($(this).hasClass('sortup')){
      $(this).removeClass('sortup').addClass('sortdown');
    }else if($(this).hasClass('sortdown')){
      $(this).removeClass('sortdown').addClass('sortup');
    }else{
      $(this).addClass('sortdown');
    }
    $(".j_stocks_search").empty();
    searchStocks(1, true, false, true);
    //caishuo.adjustFooter();
  });

  // $('.searchmenu h2 del').click(function(){
  //   $('.searchmenu a').removeClass("active");
  //   $('.searchmenu dl').removeClass("active").removeClass("selected");
  //   $('#filterstar .ratestar1 span').width(0);
  //   $('#filterstar a').attr('data-filter',0);
  //   $(this).hide();
  //   $(".j_stocks_search").empty();
  //   adjustSearchMenus();
  //   searchStocks(1, true, false, true);
  //   //caishuo.adjustFooter();
  // });
  $('.searchmenu dl del').click(function(){
    $(this).closest('dl').removeClass("active").removeClass("selected").find('a').removeClass("active");
    if ($(this).closest('dl').attr('id') == 'filterstar'){
      var starspan = $(this).closest('dl').find('.ratestar1');
      starspan.find('span').width(0);
      starspan.closest('a').attr('data-filter', 0);
    }
    $('.searchmenu h2 del').toggle($('.searchmenu a.active').length>0);
    $(".j_stocks_search").empty();
    adjustSearchMenus();
    searchStocks(1, true, false, true);
    //caishuo.adjustFooter();
    return false;
  });

  $('#filterstar .ratestar1').mouseover(function(e){
    var offleft = e.offsetX+21 || e.originalEvent.layerX +21;
    var w = Math.floor(offleft / $(this).width() * 5);
    $(this).find('span').width(w*20 +'%');
  }).mousemove(function(e){
    var offleft = e.offsetX+21 || e.originalEvent.layerX +21;
    var w = Math.floor(offleft / $(this).width() * 5);
    $(this).find('span').width(w*20 +'%');
  }).mouseout(function(){
    var w = $(this).closest('a').attr('data-filter');
    $(this).find('span').width(w*20 +'%');
  }).click(function(e){
    var offleft = e.offsetX+21 || e.originalEvent.layerX +21;
    var w = Math.floor(offleft / $(this).width() * 5);
    $(this).closest('a').attr('data-filter', w);
  });

  if ($.isEmptyObject(_pre_search_params["search"])){
    $(".exchange_market dt").trigger("click");
    $(".stockIndex").show();
    loadMarketIndex();
  }else{
    setSearchConditions(_pre_search_params);
    adjustSearchMenus();
    $("#j_stockresult").show();
    // searchStocks(1, true, false);
  }

  setInitialStateWhenFirstLoad();
})


function adjustSearchMenus(){
	if (getSearchConditions()["market_region"] == "cn"){
		$(".without_market_cn").hide();
	}else{
		$(".without_market_cn").show();
	}
	
	var except_considerations = ["consideration_tg", "consideration_bg", "consideration_gg", "consideration_hg"];
	if (getSearchConditions()["opinion"] != undefined || except_considerations.indexOf(getSearchConditions()["consideration"]) >= 0){
		marketCnMenu().addClass("disabled");
	}else{
		marketCnMenu().removeClass("disabled");
	}
}

function marketCnMenu(){
	return $(".searchmenu dd[data-name=market_region] a[data-filter=cn]");
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

function getCurrentPage() {
	return parseInt($(".j_stocks_search").attr("current_page"));
}

// 从url中得到参数键值对
function getSearchParamsFromUrl(){
  var params_str = window.location.href.split("#")[1] || "";
  var search_conditions = {};
  $.each(params_str.split("&"), function(){
    var attr = this.split("=")[0], value = this.split("=")[1];
    if (attr != "" && value != ""){
      search_conditions[attr] = value;
    }
  })
  return search_conditions;
}

//搜索及排序参数实时add to url
function setSearchParamsToUrl(search_conditions, sort_conditions){
  var params_str = "/stocks?";
  $.each(search_conditions, function(index){
    if (index != "" && search_conditions[index] != ""){
      params_str += "search[" + index + "]=" + search_conditions[index] + "&";
    }
  })
  $.each(sort_conditions, function(index){
    if (index != "" && sort_conditions[index] != ""){
      params_str += "sort[" + index + "]=" + sort_conditions[index] + "&";
    }
  })
  var url = params_str.substring(0, params_str.length-1);
  changeBrowserUrl(url, search_conditions, sort_conditions);
}

function changeBrowserUrl(url, search_conditions, sort_conditions){
  if (window.history){
    window.history.pushState({search: search_conditions, sort: sort_conditions}, document.title, url);
  }
}

//当初次加载时state值初始化
function setInitialStateWhenFirstLoad(){
  if (window.history){
    var state_params = {};
    state_params["search"] = getSearchConditions();
    state_params["sort"] = getSortConditions();
    window.history.replaceState(state_params, document.title, window.location.href);
  }
}

function getSearchConditions() {
	var search_params = {};
	$('.searchmenu').find('a.active').each(function(){
		search_params[$(this).parent().attr('data-name')] = $(this).attr('data-filter');
	});
	return search_params;
}

function getSortConditions() {
	var direction = "desc";
	var sort_column = "";
	if($(".j_filter_order .sortdown").length > 0){
		sort_column = $(".j_filter_order .sortdown").attr("data-name");
		direction = "desc";
	}else if($(".j_filter_order .sortup").length > 0){
		sort_column = $(".j_filter_order .sortup").attr("data-name");
		direction = "asc";
	}
	return { sort_by: sort_column, direction: direction };
}

function searchStocks(page, refresh, scroll, reset_url) {
	removeMarketIndexDiv();
	addBarloadingDiv();
	$('div.addmore').hide();
	var search_conditions = getSearchConditions();
	var sort_conditions = getSortConditions();
	//reset_url控制是否需要动态改变url，并pushstate信息
	//history go back时不只需要重新load对应数据，不操作pushstate；浏览器访问时，show more暂时也不改变分页信息
	if (reset_url) setSearchParamsToUrl(search_conditions, sort_conditions);
    $.post("/stocks/search", {search: search_conditions, sort: sort_conditions, page: page, refresh: refresh, scroll: scroll }, function(datas){
      Translate.parseBody(document.getElementById('j_stockresult'));
    });
}

function removeMarketIndexDiv(){
	$(".stockIndex").remove();
	$("#j_stockresult").show();
}

function addBarloadingDiv(){
	removeBarloadingDiv();
	$(".j_stocks_search").append("<div class='barloading' style='min-height:200px;clear:both;'></div>");
}

function removeBarloadingDiv(){
	$(".j_stocks_search .barloading").remove();
}


//批量设置搜索条件 search and sort
function setSearchConditions(conditions){
  var search = conditions["search"];
  var sort = conditions["sort"];
	var common_conditions = ["market_region", "sector", "style", "opinion", "trend", "consideration", "capitalization"];
	$.each(common_conditions, function(){
		if (search[this] != undefined){
      var dd_a = $("dd[data-name=" + this + "] a[data-filter='" + search[this] + "']");
			dd_a.parent().parent().addClass("active").addClass("selected");
			dd_a.addClass("active").siblings().removeClass("active");
		}else{
      $("dd[data-name=" + this + "] a").removeClass("active");
      $("dd[data-name=" + this + "]").parent().removeClass("active").removeClass("selected");
    }
	})

	if (search["score"] != undefined){
		$('#filterstar').addClass('active').addClass('selected');
		$('#filterstar dd a').attr('data-filter', search["score"]).addClass('active');
		$('.ratestar1 span').attr('style', 'width: '+ (parseInt(search["score"])*20).toString() +'%;');
	}else{
    $('#filterstar').removeClass('active').removeClass('selected');
    $('#filterstar dd a').attr('data-filter', 0).removeClass('active');
  }

	//sort
	if (sort["sort_by"] != undefined){
		$(".j_filter_order span").removeClass("sortup").removeClass("sortdown");
		var sort_class = sort["direction"] == "desc" ? "sortdown" : "sortup";
		$(".j_filter_order span[data-name="+ sort["sort_by"] +"]").addClass(sort_class);
	}

  $('.searchmenu h2 del').toggle($('.searchmenu a.active').length>0)
}
