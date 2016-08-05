// @实时加载三大股指
var MarketIndex = {

  updateRtQuote: function(index_datas){
    StockIndex(index_datas);
    this.StocksMarketIndex(index_datas);
  },

  // 更新stocks首页指数
  StocksMarketIndex: function(data){
    for (var symbol in data){
      var item = data[symbol], 
          $dd = $('.stockIndex .stockStatus li').filter(function(){return symbol == $(this).attr("data-market-symbol")}).find("a");
      var operator = parseFloat(item.change)>=0 ? "+": "";
      $dd.removeClass("gray").removeClass("plus").removeClass("mins").addClass(parseFloat(item.percent)>=0? 'plus':'mins');
      $dd.find("b:eq(0)").text(item.index);
      $dd.find("b:eq(1)").text(operator+accounting.toFixed(item.change, 2) + " " + operator+accounting.toFixed(item.percent, 2) + "%");
    }
  }

};

var updatePreview = function(c){
  var boundx = $("#cropbox").width(),
  boundy = $("#cropbox").height(),

  preview_100 = $('#preview_100'),
  preview_40 = $('#preview_40'),
  preview_30 = $('#preview_30'),
  preview_24 = $('#preview_24'),
  preview_100_image = preview_100.find('img');

  if (parseInt(c.w) > 0){

    $('#user_crop_x').val(c.x);
    $('#user_crop_y').val(c.y);
    $('#user_crop_w').val(c.w);
    $('#user_crop_h').val(c.h);
    
    var p_100_x = 100 / c.w;
    var p_100_y = 100 / c.h;
      
    preview_100_image.css({
      width: Math.round(p_100_x * boundx) + 'px',
      height: Math.round(p_100_y * boundy) + 'px',
      marginLeft: '-' + Math.round(p_100_x * c.x) + 'px',
      marginTop: '-' + Math.round(p_100_y * c.y) + 'px'
    });

    var p_40_x = 40 / c.w;
    var p_40_y = 40 / c.h;

    preview_40.find('img').css({
      width: Math.round(p_40_x * boundx) + 'px',
      height: Math.round(p_40_y * boundy) + 'px',
      marginLeft: '-' + Math.round(p_40_x * c.x) + 'px',
      marginTop: '-' + Math.round(p_40_y * c.y) + 'px'
    });
    
    var p_30_x = 30 / c.w;
    var p_30_y = 30 / c.h;

    preview_30.find('img').css({
      width: Math.round(p_30_x * boundx) + 'px',
      height: Math.round(p_30_y * boundy) + 'px',
      marginLeft: '-' + Math.round(p_30_x * c.x) + 'px',
      marginTop: '-' + Math.round(p_30_y * c.y) + 'px'
    });

    var p_24_x = 24 / c.w;
    var p_24_y = 24 / c.h;

    preview_24.find('img').css({
      width: Math.round(p_24_x * boundx) + 'px',
      height: Math.round(p_24_y * boundy) + 'px',
      marginLeft: '-' + Math.round(p_24_x * c.x) + 'px',
      marginTop: '-' + Math.round(p_24_y * c.y) + 'px'
    });

  }
};

// @Jcrop 初始化
var userJcropInit = function(){
  var jcrop_api, boundx, boundy;

  $('#cropbox').Jcrop({
    onChange: updatePreview,
    onSelect: updatePreview,
    aspectRatio: 1
  },function(){
    var bounds = this.getBounds();
    boundx = bounds[0];
    boundy = bounds[1];
    jcrop_api = this;
    if(boundx >= boundy){
      bound_length = boundy - 30;
      pointer_x = (boundx - bound_length) / 2;
      jcrop_api.setSelect([pointer_x, 15, bound_length + pointer_x, bound_length + 15]);
    }else{
      bound_length = boundx - 30;
      pointer_y = (boundy - bound_length) / 2;
      jcrop_api.setSelect([15, pointer_y, bound_length + 15, bound_length + pointer_y]);
    }
  });
};

// 设置裁剪坐标
var updateCoordinate = function(c){
  if (parseInt(c.w) > 0){
    $('#user_crop_x').val(c.x);
    $('#user_crop_y').val(c.y);
    $('#user_crop_w').val(c.w);
    $('#user_crop_h').val(c.h);
  }
}

// 分享到weibo/facebook/twitter
var Share = {
  weibo: function(shared_url, shared_title){
    window.open('http://service.weibo.com/share/share.php?url=' + encodeURIComponent(shared_url) + '&title=' + encodeURIComponent(shared_title) + '&appkey=1343713053&searchPic=false');
  },
  facebook: function(shared_url, shared_title){
    window.open('http://www.facebook.com/sharer.php?u=' + encodeURIComponent(shared_url) + '&t=' + encodeURIComponent(shared_title));
  },
  twitter: function(shared_url, shared_title){
    window.open('http://twitter.com/home?status=' + encodeURIComponent(shared_url) + '' + encodeURIComponent(shared_title));
  }
}

//分享到新浪微博
function share_to_sina_weibo(shared_url, shared_title, pic){
  url = 'http://service.weibo.com/share/share.php?url=' + encodeURIComponent(shared_url) + '&title=' + encodeURIComponent(shared_title) + '&appkey=1343713053&searchPic=false'
  if(pic != null){
    url += ("&pic="+pic);
  }
  window.open(url);
}

function scrollToWindowTop(){
  window.scrollTo(0,0);
}

//设置通知已读
function setNotificationsReaded(notice_ids){
  //todo 打开下面
  //$.post("/ajax/notifications/mark_read", {ids: notice_ids})
}

//获取url中某个参数值
function getUrlParameter(sParam){
  var sPageURL = window.location.search.substring(1);
  var sURLVariables = sPageURL.split('&');
  for(var i=0; i<sURLVariables.length; i++){
    var sParameterName = sURLVariables[i].split('=');
    if (sParameterName[0] == sParam){
      return sParameterName[1];
    }
  }
}

function calPrefix(value){
  return value>0 ? "+" : "";
}

function CaishuoAlert(msg){
  CaishuoDialog.open({theme:'alert',title:'提示',content:msg});
}

function CaishuoConfirm(msg, callback){
  CaishuoDialog.open({theme:'confirm',title:'确认',content:msg,callback: callback});
}

// 浮点精确计算（接近）
// 使用地方：1、orders.js; 2、...
var AccMath = {
  add: function(s1, s2){
    var multi_value = this.maxMultiplyValue(s1, s2);
    return (Math.round(s1 * multi_value) + Math.round(s2 * multi_value))/multi_value;
  },

  sub: function(s1, s2){
    var multi_value = this.maxMultiplyValue(s1, s2);
    return (Math.round(s1 * multi_value) - Math.round(s2 * multi_value))/multi_value;
  },

  mul: function(s1, s2){
    var multi_value = this.maxMultiplyValue(s1, s2);
    return (Math.round(s1 * multi_value) * Math.round(s2 * multi_value))/(multi_value * multi_value);
  },

  div: function(s1, s2){
    var multi_value = this.maxMultiplyValue(s1, s2);
    return Math.round(s1 * multi_value)/Math.round(s2 * multi_value);
  },

  maxMultiplyValue: function(s1, s2){
    var r1, r2;
    try {
      r1 = (1 * s1).toString().split(".")[1].length;
    }
    catch (e) {
      r1 = 0;
    }
    try {
      r2 = (1 * s2).toString().split(".")[1].length;
    }
    catch (e) {
      r2 = 0;
    }
    //考虑到本站的使用场景，把最大的指数值定为6
    var max_value = Math.max(r1, r2) > 6 ? 6 : Math.max(r1, r2)
    return Math.pow(10, max_value);
  }
}

// JS 获得 Cookie
function getCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
    if (c.indexOf(nameEQ) == 0) return unescape(c.substring(nameEQ.length,c.length));
  }
  return null;
}

function setCookie(c_name, value, expiredays)
{
  var exdate = new Date();
  exdate.setDate(exdate.getDate()+expiredays);
  document.cookie = c_name+ "=" + escape(value) + ((expiredays==null) ? "" : ";expires="+exdate.toGMTString());
}

// 判断用户是否登录
function isLogined(){
  var lastLoginedAt = parseInt(getCookie('last_request_at')) * 1000;
  return getCookie('logined') == 'true' && ($.now() - lastLoginedAt <= 10800000)
}

// 判断用户是否被锁定
function isAvailable() {
	res = true;
  $.ajax({
    url: "/ajax/users/check_available",
    dataType: "json",
		type: "GET",
		async: false,
    success: function( data ) {
			console.log(data);
      res = data.available;
    }
  });
	return res;
}

function openLoginDialog(){
  CaishuoDialog.open({theme:"custom", skin:'login',
        title:'登录财说<i class="close-window" onclick="CaishuoDialog.close()"></i>',
        content: $("#landing-docker")});
}

// $.fn.BubbleBox.Events = {
//   userFetchEvent: function(uid, callback){
//     $.get('/ajax/users/'+uid+'/bubble', function(data) {
//       callback(data);
//     }, 'json');
//   },
//   userFocusEvent:function(uid, callback){
//     if (!isLogined()){
//       openLoginDialog();
//     }else{
//       $.post('/ajax/users/'+uid+'/toggle_follow', {}, function(data){
//         callback(data.followed);
//       },'json');
//     }
//   },
//   basketStockFetchEvent:function(sid, callback){
//     StockDetail.show(sid, callback);
//   },
//   stockFetchEvent:function(sid, callback){
//     $.get('/ajax/stocks/'+sid+'/bubble', function(data) {
//       callback(data);
//     }, 'json');
//   },
//   stockFocusEvent:function(sid, callback){
//     if (!isLogined()){
//       openLoginDialog();
//     }else{
//       $.post("/ajax/stocks/"+sid+"/follow_or_unfollow", {}, function(data){
//         callback(data.followed);
//       },'json');
//     }
//   }
// }
  
//user、stock卡片浮动层
function initBubbleBox(){
  try{
    $('*[data-uid].j_bop, *[data-sid].j_bop').BubbleBox();
  }catch(e){
    
  }
}

function sortColumn(){
  $('.sortcolumn').columnsor();
}


$(function(){

  // 弹框登录
  $(document).on('click', '.j-login-popup', function(event){
    if(isLogined()){
      //return true;
      window.location.reload();
    } else {
      openLoginDialog();
    }
  })

  initBubbleBox();

  // 用户锁定下单提示
  // $(document).on('click', '.j-order-alert', function(event){
  //   if(isAvailable()){
  //     return true;
  //   } else {
  //     CaishuoAlert("对不起，您的账号未绑定或已被锁定，暂不可交易！");
		// 	event.stopImmediatePropagation();
  //     return false;
  //   }
  // })

  // $('.close-window').on('click', function(){
  //   $('#j_popup_err').css('visibility', 'hidden');
  //   $(this).parents('.login-popup-dialog').hide();
  // })

  // $('.login-popup-dialog #user_email').focus(function(){
  //   $('#j_popup_err').css('visibility', 'hidden');
  // })

  // 通知
  $(".notice > .notice-title").click(function(){
    $(".notice > .news").toggle();
    if ($(".notice > .news").html() == ""){
      $.get("/ajax/users/unread_notifications");
    }
  })

  $(document).on("click", '.selectbox, .searchgroup', function(){
    $(window).trigger('click');
    $(this).find('ul').show();
    return false;
  });

  $(document).on("click", '.selectoption li', function(){
    $(this).parents('.selectbox').find('input').val($(this).attr('data-value'));
    $(this).parents('.selectbox').find('label').text($(this).text());
    $(this).parent().hide();
    $(this).addClass("active").siblings().removeClass("active");
    return false;
  }).blur();

  $(window).click(function(){
    $('.selectoption, .searchresult').hide();
  });

  /* GA 检测点击事件的链接
   *
   * 链接需要具有的属性：
   *   data-ga-category
   *   data-ga-action
   *   data-ga-label    标签
   *   data-ga-value    值，只能是number，暂时不使用
   *
   * //以下说明失效
   * 说明：area 属性的值在发送给 GA 的时候，会在前边增加 window.CURRENT_LOCATION，
   *       mark 属性则原样发送给 GA，适用于不关心来自哪个页面，只关心约定的值的情况，
   *       area 和 mark 可同时为空，则此时发送给 GA 的标识为 window.CURRENT_LOCATION
   * 注意：使用了 GA 检测的链接，需要新窗口打开，否则有可能 GA 代码没执行完就跳转了
   */
  $(document).on('click', ".j_event_tracking",function(event) {
      var $this = $(this);
      addTrackEvent($this.data("ga-category"), $this.data("ga-action"), $this.data("ga-label"), $this.data("ga-value"));
  });

})


//
// 数量 + -
// input要有几个属性：step（步长），min（允许的最小值，一般是和step值相同），max(如果不做限制，可填入一个较大的值，如1000000)
//
var Amount = {
  add: function(input_obj){
    var step_value = parseInt($(input_obj).attr("step")),
        now_number = parseInt($(input_obj).val()),
        total_number,
        min_value = parseInt($(input_obj).attr("min")),
        real_max_value = parseInt($(input_obj).attr("max")),
        max_value = real_max_value; //A股交易可清仓非step股数
        // max_value = Math.floor(real_max_value/step_value)*step_value;
    if (isNaN(now_number) || now_number < min_value){
      total_number = min_value;
    }else{
      total_number = now_number + step_value;
      total_number = max_value < total_number ? max_value : total_number;
    }
    $(input_obj).val(total_number);
    Amount.adjustKbdStyle(input_obj);
  },

  reduce: function(input_obj){
    var step_value = parseInt($(input_obj).attr("step"));
    var now_number = parseInt($(input_obj).val());
    var total_number;
    var min_value = parseInt($(input_obj).attr("min"));
    var max_value = parseInt($(input_obj).attr("max"));
    if (isNaN(now_number) || now_number <= min_value){
      total_number = min_value;
    }else{
      total_number = (Math.ceil(now_number/step_value)-1)*step_value;
    }
    $(input_obj).val(total_number);
    Amount.adjustKbdStyle(input_obj);
  },

  priceAdd: function(input_obj){
    this.price(input_obj, "add");
  },

  priceReduce: function(input_obj){
    this.price(input_obj, "reduce");
  },

  //价格+-
  price: function(input_obj, type){
    var step_value = parseFloat($(input_obj).attr("step")),
        now_price = parseFloat($(input_obj).val()) || 0,
        min_value = parseFloat($(input_obj).attr("min")),
        max_value = parseFloat($(input_obj).attr("max")),
        price = type=="add" ? (now_price*100+1).round()/100 : (now_price*100-1).round()/100;
    $(input_obj).next().removeClass("limit").end().prev().removeClass("limit");
    if (!isNaN(max_value) && price > max_value){
      $(input_obj).val(max_value);
      $(input_obj).next().addClass("limit");
    }else if(!isNaN(min_value) && price < min_value){
      $(input_obj).val(min_value);
      $(input_obj).prev().addClass("limit");
    }else{
      $(input_obj).val(price);
    }
  },

  adjustKbdStyle: function(input_obj){
    var total_number = parseInt($(input_obj).val());
    var max_value = parseInt($(input_obj).attr("max"));
    var min_value = parseInt($(input_obj).attr("min"));
    $(input_obj).siblings().removeClass("limit");
    if (total_number == min_value){
      $(input_obj).prev().addClass("limit");
    }
    if (max_value <= total_number){
      $(input_obj).next().addClass("limit");
    }
  },

  checkInputIsNumber: function(input_obj){
    var adjusted_value = $(input_obj).val().replace(/[^0-9]+/,'').replace(/[^0-9]+/,'');
    if (adjusted_value != $(input_obj).val()) $(input_obj).val(adjusted_value);
  },

  checkInputIsDigital: function(input_obj){
    var adjusted_value = $(input_obj).val().replace(/[^0-9\.]+/,'').replace(/[^0-9\.]+/,'');
    if (adjusted_value != $(input_obj).val()) $(input_obj).val(adjusted_value);
  },

  adjustUserInputNumber: function(input_obj){
    var number = parseInt($(input_obj).val());
    if (isNaN(number)){
      this.reduce(input_obj);
    }else{
      var step_value = parseInt($(input_obj).attr("step"));
      var volume = parseInt(parseInt($(input_obj).val())/step_value);
      var min_value = parseInt($(input_obj).attr("min"));
      var max_value = parseInt($(input_obj).attr("max"));
      var adjust_max_value = Math.floor(max_value/step_value)*step_value;
      if (number != volume*step_value || number < min_value){
        var input_value = (volume+1)*step_value > adjust_max_value ? adjust_max_value : (volume+1)*step_value;
        $(input_obj).val(input_value);
      }
      if (number > adjust_max_value){
        $(input_obj).val(adjust_max_value);
      }
    }
  }
}


//日期timestamp转date time: 例如(new Date(timestamp)).format("yyyy-MM-dd hh:mm:ss");
Date.prototype.format = function(format) {
    var o = {
        "M+": this.getMonth() + 1,
        // month
        "d+": this.getDate(),
        // day
        "h+": this.getHours(),
        // hour
        "m+": this.getMinutes(),
        // minute
        "s+": this.getSeconds(),
        // second
        "q+": Math.floor((this.getMonth() + 3) / 3),
        // quarter
        "S": this.getMilliseconds()
        // millisecond
    };
    if (/(y+)/.test(format) || /(Y+)/.test(format)) {
        format = format.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
    }
    for (var k in o) {
        if (new RegExp("(" + k + ")").test(format)) {
            format = format.replace(RegExp.$1, RegExp.$1.length == 1 ? o[k] : ("00" + o[k]).substr(("" + o[k]).length));
        }
    }
    return format;
};

//扩展 保留几位小数，返回还是number
Number.prototype.round = function(digit_num){
  return parseFloat(this.toFixed(digit_num));
}

Array.prototype.remove = function(val) {
  var index = this.indexOf(val);
  if (index > -1) {
      this.splice(index, 1);
  }
};

String.prototype.replaceAll = function(reallyDo, replaceWith, ignoreCase) {  
    if (!RegExp.prototype.isPrototypeOf(reallyDo)) {  
        return this.replace(new RegExp(reallyDo, (ignoreCase ? "gi": "g")), replaceWith);  
    } else {
        return this.replace(reallyDo, replaceWith);  
    }
}


// div需要属性: data-basket-id, id: basket_chart_*, class: basket_chart
// 页面加载后调用 BasketMiniChart.init();
var BasketMiniChart = {
  init: function(){
    $(".basket_chart").each(function(){
      var basket_id = $(this).attr("data-basket-id"), chart_container = $("#basket_chart_"+basket_id);
      BasketMiniChart.draw(chart_container, basket_id);
    })
  },

  draw: function(chart_container, basket_id){
    $.get("/ajax/baskets/"+basket_id+"/chart_datas", {}, function(response){
      var basket_datas = response.simulated.length == 0 ? response.basket : response.simulated;
      var market_datas = response.market_data;
      var start_timestamp = Math.max(basket_datas[0][0], market_datas[0][0]);
      var basket_datas_percent = BasketMiniChart.calculateReturnDatas(basket_datas, start_timestamp);
      var market_datas_percent = BasketMiniChart.calculateReturnDatas(market_datas, start_timestamp);
      BasketMiniChart.drawChart(chart_container, basket_datas_percent, market_datas_percent);
    })
  },

  calculateReturnDatas: function(ori_datas, start_timestamp){
    var datas = [];
    var adjust_datas = [];
    $.each(ori_datas, function(){
      if(this[0] >= start_timestamp){
        datas.push(this);
      }
    })
    $.each(datas, function(){
      var change_percent = (this[1] - datas[0][1])*100/datas[0][1];
      adjust_datas.push([this[0], change_percent]);
    })
    return adjust_datas;
  },

  drawChart: function(chart_container, basket_datas, market_datas){
    $(chart_container).highcharts({
        chart: {
          marginBottom: 0,
          marginTop: 0,
          marginLeft: 0,
          marginRight: 0,
          borderWidth: 1,
          borderColor: "#e5e7eb",
          animation: false
        },
        title: {
          text : null
        },
        credits: {
          enabled: false
        },
        xAxis: {
            type: 'datetime',
            labels: {
              enabled: false
            },
            offset: 0
        },
        yAxis: {
            labels: {
              enabled: false
            },
            title: {
              enabled: false
            },
            gridLineColor: '#F6F6F6',
            gridLineWidth: 1,
            tickPixelInterval: 15
        },
        tooltip: {
            enabled: false
        },
        legend: {
            enabled: false
        },
        plotOptions: {
            line: {
                // fillColor: '#EBEAEA',
                // color: '#3da1df',
                lineWidth: 1,
                marker: {
                    enabled: false
                },
                shadow: false,
                states: {
                    hover: {
                        lineWidth: 1
                    }
                },
                threshold: null,
                enableMouseTracking: false
            }
        },
        series: [{
            // type: 'line',
            name: 'basket',
            // pointInterval: 24 * 3600 * 1000,
            color: "#28abe6",
            data: basket_datas,
            animation: false
        }, {
            // type: 'line',
            name: 'market',
            // pointInterval: 24 * 3600 * 1000,
            color: "#87d13f",
            data: market_datas,
            animation: false,
        }]
    })
  }
}




// baidu ===>
// _hmt.push(['_trackEvent', category, action, opt_label, opt_value]);
// hmt_category、hmt_action 参数值由bi部门指定
// hmt_area 事件发生区域
// hmt_prefix 有些事件，只要传递一个标识，不需要知道是哪个页面的，不用加上 CURRENT_LOCATION
// function addTrackEvent(ga_category, ga_action, ga_area, no_prefix) {
//     // var ga_location = window.CURRENT_LOCATION;
//     // if (typeof ga_area != 'undefined') {
//     //     if (no_prefix) {
//     //         ga_location = ga_area;
//     //     } else {
//     //         ga_location = window.CURRENT_LOCATION + "_" + ga_area;
//     //     }
//     // }
//     if (typeof _hmt != 'undefined') {
//         _hmt.push(['_trackEvent', ga_category, ga_action, ga_area]);
//     } 
    
//     if (typeof _env != 'undefined') {
//       // 开发模式下调试用
//       console.log("trigger GA Event: ['_trackEvent', '" + ga_category + "', '" + ga_action + "', '" + ga_area + "']");
//     }
// }
// <=== baidu

//google
// function addTrackEvent(ga_category, ga_action, ga_label, ga_value) {
//     if (typeof ga != 'undefined') {
//       ga_label = ga_label || "";
//       // ga_value = ga_value || "";   //暂时没使用，只能是number
//       ga('send', 'event', ga_category, ga_action, ga_label);
//     }
    
//     if (typeof _env != 'undefined') {
//       // 开发模式下调试用
//       console.log("trigger GA Event: ['_trackEvent', '" + ga_category + "', '" + ga_action + "', '" + ga_label + "', '" + ga_value + "']");
//     }
// }

// GTM
function addTrackEvent(ga_category, ga_action, ga_label, ga_value) {
    if (typeof dataLayer != 'undefined') {
      ga_label = ga_label || "";
      // ga_value = ga_value || "";   //暂时没使用，只能是number
      dataLayer.push({
        'event': 'gaTriggerEvent',
        'gaEventCategory': ga_category,
        'gaEventAction': ga_action,
        'gaEventLabel': ga_label
      });
    }
    
    if (typeof _env != 'undefined') {
      // 开发模式下调试用
      console.log("trigger GA Event: ['_trackEvent', '" + ga_category + "', '" + ga_action + "', '" + ga_label + "', '" + ga_value + "']");
    }
}



// 公共方法，用于js对一些数据格式统一
// 注意不要轻易修改
var FormatValue = {
  percent: function(value, with_unit){
    if (value){
      var unit = with_unit == true ? "%" : "";
      return accounting.formatMoney(parseFloat(value), '') + unit;
    }else{
      return "--"
    }
  },

  upDownClass: function(value){
    if (!value) return "";
    var number = parseFloat(value);
    return number>=0 ? "plus" : "mins";
  },

  upDownOperator: function(value){
    if (!value) return "";
    var number = parseFloat(value);
    return number>=0 ? "+" : "";
  },

  price: function(value){
    return accounting.formatMoney(parseFloat(value), "");
  },

  pe: function(value){
    if (!value || value == "--") return "--";
    return accounting.formatMoney(parseFloat(value), "");
  },

  //stock/basket year/month/...  return
  itemReturn: function(value){
    return value ? value : "--"
  },

  marketValue: function(value){
    if (!value || value == "--"){
      return "--"
    }else{
      return human_number(value);
    }
  },

  marketValueForSort: function(value, usd_rate){
    if (!value || value == "--"){
      return 0
    }else{
      return this.toUsd(value, usd_rate);
    }
  },

  money_number: function(value){
    var parsed_number = parseFloat(value);
    if (!parsed_number) {
      return "--"
    }
    else {
      return accounting.formatMoney(parsed_number/100000000, "");
    }
  },

  human_number: function(value){
    var parsed_number = parseFloat(value);
    if (parsed_number > 1000000000000){
      return accounting.formatMoney(parsed_number/1000000000000, "") + "万亿";
    }else if(parsed_number > 100000000){
      return accounting.formatMoney(parsed_number/100000000, "") + "亿";
    }else if(parsed_number > 10000){
      return accounting.formatMoney(parsed_number/10000, "") + "万";
    }else if(!parsed_number){
      return "--"
    }else{
      return accounting.formatMoney(parsed_number, '');
    }
  },

  toUsd: function(value, usd_rate){
    return parseFloat(value) * parseFloat(usd_rate);
  }
}


//券商账户登录
var Account = {
  showBroker: function(){
    CaishuoDialog.open({theme:'custom',skin:'',title:'券商切换<i class="close-window" onclick="CaishuoDialog.close()"></i>',content:$('#brokerList'),btntext:'false'});
  },

  //未绑定状态弹窗
  showLogin: function(account_id, broker_info, need_comunication, show_switch){
    var html = Account.accountLoginHtml(account_id, broker_info, need_comunication, show_switch);
    CaishuoDialog.open({theme:'custom',skin:'',title:'券商登录<i class="close-window" onclick="CaishuoDialog.close()"></i>',content:$(html),btntext:'false',reset:function(){
        // $(id)[0].reset();
        // $(id).find('.errorTip').hide();
        // $(id).find('dd').removeClass().eq(0).addClass('active');
    },callback:function(){
        alert('do the real things');
        // location=location;
    },buttons:{confirm:$(html).find('button.btn_blue')}});
  },

  accountLoginHtml: function(account_id, broker_info, need_comunication, show_switch){
    var html = '<div id="brokerLogin">';
    html += '<table>';
    html += '<tr><th align="right" width="90">名称：</th><td>' + broker_info + '</td></tr>';
    html += '<input type="hidden" value="' + account_id + '" id="account_login_id" />';
    html += '<tr><th align="right">密码：</th><td><input type="password" id="account_login_password"  placeholder="请输入密码"/></td></tr>';
    if (need_comunication == "true" || need_comunication == true){
      html += '<tr><th align="right">通讯密码：</th><td><input type="password" id="communication_password" placeholder="请输入通讯密码"></td></tr>';
    }
    html += '<tr><th></th><td><span class="errorTip" style="display:none;"></span></td></tr>';
    html += '<tr><th></th><td>本次登录将保持360分钟</td></tr>';
    html += '<tr><th></th><td><button class="btn_blue" onclick="Account.login(this);">登录</button>';
    if (show_switch != false){
      html += '<a href="javascript:Account.showBroker();" class="switch">切换账户</a>';
    }
    html += "</td></tr>";
    html += '</table>';
    html += '</div>';
    return html;
  },

  checkLogined: function(account_id, show_switch, callback){
    $.post("/accounts/"+account_id+"/is_login", {}, function(datas){
      if (datas.status){
        if (callback){
          callback();
        }else{
          CaishuoDialog.close();
        }
      }else{
        Account.showLogin(account_id, datas.broker_info, datas.need_comunication, show_switch);
      }
    })
  },

  login: function(obj){
    var account_id = $("#account_login_id").val(),
        password = $("#account_login_password").val(),
        communication_password = $("#communication_password").val();

    $("#brokerLogin .errorTip").hide();
    if (password == ""){
      $("#brokerLogin .errorTip").text("请输入密码！").show();
    } else if (communication_password != undefined && communication_password == ""){
      $("#brokerLogin .errorTip").text("请输入通讯密码！").show();
    }else{
      $.post("/accounts/" + account_id + "/login", {password: password, communication_password: communication_password}, function(datas){
        if (datas.status){
          CaishuoDialog.close();
        }else{
          $("#brokerLogin .errorTip").text("验证失败，请重新输入！").show();
        }
      })
    }
  },

  refreshCash: function(account_id, callback){
    if (account_id == undefined || account_id == "") return;
    
    var last_request_at = getCookie("ta_"+account_id);
    if (last_request_at && ((new Date()).getTime() - parseInt(last_request_at) < 60000) ){
      return;
    }
    $.post("/accounts/"+account_id+"/refresh_cash", {}, function(response){
      setCookie("ta_"+account_id, (new Date()).getTime(), 1);
      callback && callback();
    })
  }
};

//举报用户
$(function(){
  $('a.abuse').click(function(){
    var uname=$(this).data().username, uid = $(this).data().uid;
    CaishuoDialog.open({content:'您是否要举报@'+uname, btntext:{confirm:'举报', cancel:'取消'}, callback:function(){
      $.post("/ajax/feedbacks/report_user", {feedback: {reportable_id: uid}}, function(response){
        CaishuoDialog.open({theme:'tip', content:'您的举报已提交，我们将尽快处理'});
      })
      return true;
    }});
  });
})

