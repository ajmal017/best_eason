// 目前 个股详情页、自选股页个股交易同时使用此js
// 修改需谨慎

var Order = {
  init: function(){
    Order.updateTotalMoney();
    Order.limitPriceRadioClickHandle();
    Order.stockSizeInputEventHandle();
    Order.limitPriceInputEventHandle();
    $("#order_type").parent().find(".selectoption li:first").trigger("click");
    $('*[data-click-tip], *[data-hover-tip]').ClickHoverTip($('#BubbleBox'));
  },

  buyStock: function(obj){
    // if (!$(obj).hasClass("active")){
      $(".trade_type").val("OrderBuy");
      var step = $(".j_stock_est_shares").attr("step");
      $(".j_stock_est_shares").val(step).attr("min", step).attr("max", 1000000);
      Order.updateTotalMoney();
      Amount.adjustKbdStyle($(".j_stock_est_shares"));
    // }
  },

  sellStock: function(obj){
    // if (!$(obj).hasClass("active")){
      $(".trade_type").val("OrderSell");
      var stock_total = parseInt($(obj).attr("stock_total"));
      var input_value = stock_total>=0 ? (stock_total<step ? 0 : stock_total) : 0;
      $(".j_stock_est_shares").val(input_value);
      var step = $(".j_stock_est_shares").attr("step");
      var min = stock_total >= step ? step : 0;
      var max = stock_total>=0 ? (stock_total<step ? 0 : stock_total) : 0;
      $(".j_stock_est_shares").attr("min", min).attr("max", max);
      Order.updateTotalMoney();
      Amount.adjustKbdStyle($(".j_stock_est_shares"));
    // }
  },

  addStockNumber: function(input_obj){
    Amount.add(input_obj);
    this.updateTotalMoney();
  },

  subStockNumber: function(input_obj){
    Amount.reduce(input_obj);
    this.updateTotalMoney();
  },

  addStockPrice: function(input_obj){
    if (Order.isMarket() == true) return;
    Amount.priceAdd(input_obj);
    this.updateTotalMoney();
  },

  subStockPrice: function(input_obj){
    if (Order.isMarket() == true) return;
    Amount.priceReduce(input_obj);
    this.updateTotalMoney();
  },

  setPrice: function(price){
    if (Order.isMarket() == true) return;
    $("#order_limit_price").val(price);
    this.updateTotalMoney();
  },

  isMarket: function(){
    return $("#order_type").val() != "0" && $("#order_type").val() != "limit";
  },

  limitPriceRadioClickHandle: function(){
    $(".selectoption .order_type").on("click", function(){
      if ($(this).attr("data-value") != "0" && $(this).attr("data-value") != "limit"){
        $('#order_limit_price').css('background','#efefef').val('市价委托').attr('disabled','disabled');
      }else{
        var price = $('#order_limit_price').attr("price");
        $('#order_limit_price').css('background','#fff').val(price).removeAttr('disabled');
      }
      setTimeout("Order.updateTotalMoney();", 100);
    })
    
    $("#order_limit_price").on("keyup", function(){
      Order.updateTotalMoney();
    })
  },

  updateTotalMoney: function(){
    Order.refreshCanTradeAlert();
    var total_number = parseInt($(".j_stock_est_shares").val());
    $("#order_stocks_total").html(total_number);
    total_number = isNaN(total_number) ? 0 : total_number;
    var stock_price = (Order.isMarket() == true) ? parseFloat($(".j_stock_price").first().val()) : parseFloat($("#order_limit_price").val());
    if ( isNaN(stock_price) ) stock_price = 0;
    var total_money = (total_number * stock_price).toFixed(2);
    $("#order_total_money").val(total_money);
    $("#j_stock_total_money").text(accounting.formatMoney(total_money, ''));
    $("#j_order_total_money").text(accounting.formatMoney(total_money, ''));
    // Order.refreshCanTradeAlert();
  },

  refreshCanTradeAlert: function(){
    if ($("input[name=trade_radio][value=buy]").is(":checked")){
      var max = Order.canBuyCount(),
          value = parseInt($(".j_stock_est_shares").val()),
          value = isNaN(value) ? 0: value,
          step = parseInt($(".j_stock_est_shares").attr("step")),
          min_value = Math.min(max, Math.max(value, step)),
          is_need_update_shares = value % step == 0; // 解决修改股数bug
      $(".orderTable .quantity .num").html("最多可买<i>" + max + "</i>股");
      if (is_need_update_shares) $(".j_stock_est_shares").attr("max", max).val(min_value);
    }else{
      var max = $("input[name=trade_radio][value=sell]").attr("stock_total");
      $(".orderTable .quantity .num").html("最多可卖<i>" + max + "</i>股");
    }
    Amount.adjustKbdStyle($(".j_stock_est_shares"));
  },

  canBuyCount: function(){
    var price = Order.isMarket() == true ? 
                parseFloat($(".orderTable .price .adjustCount input").attr("price")) : 
                parseFloat($(".orderTable .price .adjustCount input").val()),
        cash = parseFloat($(".tradeInfo span:first i:first").attr("data")),
        step = parseInt($(".j_stock_est_shares").attr("step"));
    if (price <= 0 || isNaN(price)) return 0;
    return Math.floor(cash/price/step) * step;
  },

  checkOrderNewForm: function(){
    $("#btn_submit").attr("disabled", "disabled");
    $("#btn_submit").html("下单中");
    var status = Order.checkOrderValues();
    if (status == true){
      status = Order.ajaxCreateOrder(false);
    }
    if (status == true){
      setTimeout("Order.enableSubmitBtn();", 1000);
      // 自选股页面
      if ($('#myFocus').length>0) $('#orderTable').appendTo('#myFocus');
    }else{
      Order.enableSubmitBtn();
    }
    return false;
  },

  ajaxCreateOrder: function(status){
    try{
      $.ajax({
        url: "/orders",
        type: "POST",
        dataType: "json",
        async: false,
        data: {
            order: Order.getOrderParams(),
            trade_type: $("#order_trade_type").val()
        },
        success: function (response) {
          if (response.recert == true){
            triggerBindAuth(); //页面定义
          }else if (response.login == false){
            Account.showLogin($("#trading_account_id").val(), $(".tradeInfo em:first").text(), $(".tradeInfo em:first").attr("communication"));
            status = false;
          }else if (response.error == true){
            CaishuoAlert(response.error_msg);
            status = false;
          }else{
            window.open("/orders/" + response.order_id);
            status = true;
          }
        }
      })
      return status;
    }catch(e){
      return false;
    }
  },

  enableSubmitBtn: function(){
    $("#btn_submit").removeAttr("disabled");
    $("#btn_submit").html("下单");
  },

  getOrderParams: function(){
    var order_params = {};
    var order_details_attributes = {};
    var order_detail = {};
    order_detail["est_shares"] = $(".j_stock_est_shares").val();
    order_detail["base_stock_id"] = $(".buying-power").find(".j_stock_id").val();
    order_detail["order_type"] = $("input[name='order[order_type]']").val();
    order_detail["limit_price"] = $("#order_limit_price").val();
    order_details_attributes['0'] = order_detail;
    order_params["order_details_attributes"] = order_details_attributes;
    order_params["gtd"] = $("#order_expiry").val();
    order_params["trading_account_id"] = $("#trading_account_id").val();
    return order_params;
  },

  stockSizeInputEventHandle: function(){
    $(".j_stock_est_shares").on("keyup", function(event){
      if (!(event.which == "37" || event.which == "39" || event.which == "8")){
        Amount.checkInputIsNumber(this);
        Order.updateTotalMoney();
      }
    })

    $(".j_stock_est_shares").on("blur", function(){
      Amount.adjustUserInputNumber(this);
      Order.updateTotalMoney();
    })
  },

  limitPriceInputEventHandle: function(){
    $("#order_limit_price").on("keyup", function(event){
      if (event.which == "37" || event.which == "39" || event.which == "8"){
        return true;
      }
      var adjusted_value = $(this).val().replace(/[^0-9\.]+/,'').replace(/[^0-9\.]+/,'');
      adjusted_value = adjusted_value == "" ? "" : adjusted_value.match(/([0-9]+.?[0-9]{0,3})/)[0]
      $(this).val(adjusted_value);
    })

    $("#order_limit_price").on("blur", function(){
      var price_obj = $("#order_limit_price"),
          max = parseFloat(price_obj.attr("max")),
          min = parseFloat(price_obj.attr("min")),
          price = parseFloat(price_obj.val()) || 0;

      price_obj.next().removeClass("limit").end().prev().removeClass("limit");
      if (!isNaN(max) && price > max){
        price_obj.val(max);
        price_obj.next().addClass("limit");
      }else if(!isNaN(min) && price < min){
        price_obj.val(min);
        price_obj.prev().addClass("limit");
      }
      Order.updateTotalMoney();
    })
  },

  checkOrderValues: function(){
    var status = true;
    if ($("#order_limit_price").attr("disabled") != "disabled"){
      var limit_price = $.trim($("#order_limit_price").val());
      if (limit_price == ""){
        CaishuoAlert("请填写限价！");
        status = false;
      }
    }
    if (parseInt($(".j_stock_est_shares").first().val()) <= 0){
      CaishuoAlert("股票数量不合法！");
      status = false;
    }
    
    return status;
  }
};