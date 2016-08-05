//orders new
var Order = {
  _basket_currency_unit: '$',

  pageHandler: function(){
    Order.changeAccountHandler();

    $("#amount").on("keyup", function(event){
      if (!(event.which == 37 || event.which == 39)){
        Amount.checkInputIsDigital($(this));
      }
    })

    var $slide = $( "#amountslider" );
    $slide.slider({
      range: "min",
      value: _basket_minimum_amount,
      min: 0,
      max: _user_total_cash,
      slide: function( event, ui ) {
        $( "#amount" ).val( ui.value );
        Order.adjustStockSharesByMoney();
      },
      change: function( event, ui ) {
        $( "#amount" ).val( ui.value );
        Order.adjustStockSharesByMoney();
      }
    });

    $("#amount").val($slide.slider( "value" ) );

    $("#amount").change(function(){
      var money = $(this).val();//.replace(/[^\d|.]?/g,'')
      $slide.slider('value', money);
    });

    Order.adjustStockSharesByMoney();
  },

  adjustStockSharesByMoney: function(){
    this.recalStockShares(false);
    if (this.getTotalPrice() > _user_total_cash) this.recalStockShares(true);
    this.updateTotalPrice();
    this.adjustStockWeights();
  },

  recalStockShares: function(force_floor){
    var money = this.investMoney();
    $(".j_stock_shares").each(function(){
      var weight = parseFloat($(this).parent().find(".j_stock_weight").val()),
          board_lot = parseInt($(this).parent().find(".j_stock_board_lot").val()), 
          price = parseFloat($(this).parent().find(".j_stock_price").val()),
          round_method = force_floor==true ? Math.floor : Math.round,
          shares = price==0 ? 0 : ( parseInt(round_method((money * weight)/price/board_lot) * board_lot) );
      $(this).parent().find(".j_stock_est_shares").val(shares);
      $(this).text(shares);
    })
  },

  investMoney: function(){
    return parseFloat($("#amount").val());
  },

  adjustStockWeights: function(){
    var total = this.getTotalPrice();
    $(".j_stock_shares").each(function(){
      var shares = parseInt($(this).parent().find(".j_stock_est_shares").val()), 
          price = parseFloat($(this).parent().find(".j_stock_price").val()), 
          weight = total > 0 ? (shares * price * 100 / total).round(2) : 0 ;
      $(this).next().text(weight + "%");
      $(this).next().next().next().text(accounting.formatMoney((shares*price).round(2), Order._basket_currency_unit));
    })
  },

  getTotalPrice: function(){
    var total = 0;
    $(".j_stock_shares").each(function(){
      var shares = parseInt($(this).parent().find(".j_stock_est_shares").val()), 
          price = parseFloat($(this).parent().find(".j_stock_price").val());
      total += (shares * price).round(2);
    })
    return total;
  },

  updateTotalPrice: function(){
    var total = this.getTotalPrice();
    $("#TotalPrice").text(accounting.formatMoney(total, Order._basket_currency_unit));
    $("#order_total_money").val(total.toFixed(2));
  },

  stockSharesValid: function(){
    var total_shares = 0;
    $(".j_stock_est_shares").each(function(){
      total_shares += parseInt($(this).val());
    })
    if (total_shares>0){
      return true;
    }else{
      CaishuoAlert("购买数量至少有一个大于0！");
    }
  },

  checkOrderNewForm: function(){
    $("#btn_submit").attr("disabled", "disabled");
    $("#btn_submit").val("下单中");
    var status = this.stockSharesValid();
    if (status == true){
      status = Order.ajaxCreateOrder(status);
    }
    if (status == true){
      setTimeout("Order.enableSubmitBtn();", 1000);
    }else{
      Order.enableSubmitBtn();
    }
    
    return false;
  },

  // 当点击下单后，1秒钟之后把btn的disabled attr去掉
  enableSubmitBtn: function(){
    $("#btn_submit").removeAttr("disabled");
    $("#btn_submit").val("下单");
  },

  ajaxCreateOrder: function(status){
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
        if (response.error == true){
          CaishuoAlert(response.error_msg);
          status = false;
        }else{
          window.location.href = "/orders/" + response.order_id;
          status = true;
        }
      }
    })
    return status;
  },

  getOrderParams: function(){
    var order_params = {};
    var order_details_attributes = {};
    order_params["basket_mount"] = $("#order_basket_mount").val();
    order_params["basket_id"] = $("#order_basket_id").val();
    order_params["trading_account_id"] = $("#trading_account_id").val();
    $(".wrapCorner table tbody tr").each(function(i){
      var order_detail = {};
      order_detail["est_shares"] = $(this).find(".j_stock_est_shares").val();
      order_detail["base_stock_id"] = $(this).find(".j_stock_id").val();
      order_details_attributes[i.toString()] = order_detail;
    })
    order_params["order_details_attributes"] = order_details_attributes;
    return order_params;
  },

  changeAccountHandler: function(){
    $(".selectoption li.account").on("click", function(){
      window.location.href = "/baskets/"+_basket_id+"/orders/new?account_id="+$(this).attr("data-value");
    })
  }
}




// 按比例卖basket: orders sell
var BasketSell = {

  pageHandler: function(){
    $("#amount").on("keyup", function(event){
      if (!(event.which == 37 || event.which == 39)){
        Amount.checkInputIsDigital($(this));
      }
    })

    $('.tradeTime').timeformat(timedata, '%stat% %market% %datetime%', 'yyyy-mm-dd hh:ii:ss', market);

    var $slide = $( "#amountslider" );

    $slide.slider({
      range: "min",
      value: _total_value,
      min: 0,
      max: _total_value,
      slide: function( event, ui ) {
        $( "#amount" ).val( ui.value );
        BasketSell.adjustSelledStockShares();
      },
      change: function( event, ui ){
        $( "#amount" ).val( ui.value );
        BasketSell.adjustSelledStockShares();
      }
    });

    $( "#amount" ).val($slide.slider( "value" ) );

    $( "#amount" ).change(function(){
      var money = $(this).val();
      $slide.slider('value', money);
    });

    BasketSell.refreshStocksWeight();

    BasketSell.adjustSelledStockShares();
  },

  adjustSelledStockShares: function(){
    var money = this.selledMoney();
    $(".j_stock_count").each(function(){
      var holding_shares = parseInt($(this).text()),
          price = parseFloat($(this).parent().find(".j_stock_price").val()),
          weight = parseFloat($(this).parent().find(".j_stock_weight").text())/100,
          board_lot = parseInt($(this).parent().attr("board_lot")),
          est_shares = (money * weight / price / board_lot).round() * board_lot,
          selled_shares = est_shares > holding_shares ? holding_shares: est_shares;
      $(this).next().text(selled_shares);
      $(this).parent().find(".j_stock_est_shares").val(selled_shares);
    })
    this.updateTotalPrice();
  },

  selledMoney: function(){
    return parseFloat($("#amount").val());
  },

  updateTotalPrice: function(){
    var total = 0;
    $(".themeStocks").find(".j_stock_est_shares").each(function(){
      var share = parseInt($(this).val());
      var price = parseFloat($(this).parent().find(".j_stock_price").val());
      total += share * price;
    })
    $(".total_money").text(accounting.formatMoney(total.toFixed(2), ''));
  },

  refreshStocksWeight: function(){
    var total_value = this.stocksTotalValue();
    $(".j_stock_weight").each(function(){
      var price = parseFloat($(this).parent().find(".j_stock_price").val());
      var count = parseInt($(this).next().next().next().text());
      var weight = (price*count*100/total_value).toFixed(2);
      $(this).text((isNaN(weight) ? 0 : weight) + "%");
    })
  },

  stocksTotalValue: function(){
    var total = 0;
    $(".j_stock_count").each(function(){
      var count = parseInt($(this).text());
      var price = parseFloat($(this).parent().find(".j_stock_price").val());
      total += price*count;
    })
    return total;
  },

  stockSharesValid: function(){
    var total_shares = 0;
    $(".j_stock_est_shares").each(function(){
      total_shares += parseInt($(this).val());
    })
    if (total_shares>0){
      return true;
    }else{
      CaishuoAlert("卖出数量至少有一个大于0！");
    }
  },

  checkOrderSellForm: function(form_obj){
    $("#btn_submit").attr("disabled", "disabled").val("下单中");
    var status = this.stockSharesValid();
    if (status == true) status = BasketSell.ajaxCreateOrder(false);
    if (status == true){
      setTimeout("BasketSell.enableSubmitBtn();", 1000);
    }else{
      $("#btn_submit").removeAttr("disabled").val("下单");
    }
    return false;
  },

  ajaxCreateOrder: function(status){
    $.ajax({
      url: "/orders",
      type: "POST",
      dataType: "json",
      async: false,
      data: {
          order: BasketSell.getOrderParams(),
          trade_type: $("#order_trade_type").val()
      },
      success: function (response) {
        if (response.error == true){
          CaishuoAlert(response.error_msg);
          status = false;
        }else{
          window.location.href = "/orders/" + response.order_id;
          status = true;
        }
      }
    })
    return status;
  },

  getOrderParams: function(){
    var order_params = {};
    var order_details_attributes = {};
    $(".themeStocks tbody tr").each(function(i){
      var order_detail = {};
      order_detail["est_shares"] = $(this).find(".j_stock_est_shares").val();
      order_detail["base_stock_id"] = $(this).find(".j_stock_id").val();
      order_details_attributes[i.toString()] = order_detail;
    })
    order_params["order_details_attributes"] = order_details_attributes;
    order_params["basket_id"] = $("#order_basket_id").val();
    order_params["trading_account_id"] = $("#trading_account_id").val();
    return order_params;
  },

  enableSubmitBtn: function(){
    $("#btn_submit").removeAttr("disabled");
    $("#btn_submit").val("下单");
  }
}