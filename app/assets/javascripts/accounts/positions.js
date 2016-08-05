//
// adjust
//
var Adjust = {
  init: function(){
    // Adjust.autocompleteHandle();
    Adjust.initAutoComplete();

    $(document).on("click", '.asButton .buy', function(){
      Adjust.renderTradingContent("buy", this);
    });

    $(document).on("click", '.asButton .sell', function(){
      Adjust.renderTradingContent("sell", this);
    });

    $(document).on("click", 'label.cancel', function(){
      $("#orderForm").hide();
    });

    Adjust.refreshStocksWeight();

    AdjustOrder.limitPriceRadioClickHandle();
  },

  initAutoComplete: function(){

    $('.searchgroup').searchBox({
      source: function(target){
        var $retBox = $(target).parent().find('ul.searchresult');
        var $request = $.trim($(target).val());
        $.get('/ajax/stocks/search', {term: $request}, function(data){
          if ($request == data.term){
            if (data.stocks.length > 0){
              $retBox.empty();
              $.each(data.stocks, function(index, item){
                var liHtml = "<li stock_id='" + item.stock_id + "' symbol='" +  item.symbol + "' area='" + item.area + "'>"; 
                liHtml += "<span class='code'>" + $.highlight(item.symbol, $request) + "</span>";
                liHtml += "<span class='name'>" + $.highlight(item.company_name, $request) + "</span>";
                liHtml += "</li>";
                $retBox.append(liHtml);
              })
              $retBox.fadeIn();
            }else{
              $retBox.empty().fadeOut(); 
            }
          }

        })
      },

      select: function(target){
        if (!Adjust.checkSymbolExist(target.attr('symbol'))){
          Adjust.addStockToList(target.attr('stock_id'));
        }else{
          CaishuoAlert("列表中已经存在！");
        }
      }
    });  

  },

  checkSymbolExist: function(symbol){
    var status = false;
    $(".themeStocks tbody tr").each(function(){
      var sym = $(this).find(".j_stock_symbol").text();
      if (sym == symbol){
        status = true;
      }
    })
    return status;
  },

  addStockToList: function(stock_id){
    $.get("/accounts/"+gon.account_id+"/positions/adjust_add_stock", {stock_id: stock_id}, function(response){

    })
  },

  showFloat: function(){
    $('#FloatWindow').fadeIn();
    $('#FloatWindow .FloatContent').slideDown();
    $('body').addClass('fixed');
  },

  hideFloat: function(){
    $("#orderForm").remove();
  },

  renderTradingContent: function(trade_type, btn_obj){
    $("#stock_trade_content").html("loading......");
    Adjust.showFloat();
    stock_id = $(btn_obj).parent().attr("stock_id");
    $.get("/accounts/"+gon.account_id+"/positions/trade_basket_stock?type=" + trade_type, {stock_id: stock_id, original_basket_id: AdjustOrder._original_basket_id}, function(response){
      eval(response);
      $(btn_obj).closest('tr').after($("#orderForm").show());
      AdjustOrder.updateTotalMoney();
      $('*[data-click-tip], *[data-hover-tip]').ClickHoverTip($('#BubbleBox'));
    })
  },

  checkCanAddAreaStocks: function(area){
    return $(".themeStocks tbody tr:first").attr("area") == area
  },

  refreshStocksWeight: function(){
    var total_value = this.stocksTotalValue();
    $(".j_stock_weight").each(function(){
      var price = parseFloat($(this).next().next().next().attr("data"));
      var count = parseInt($(this).next().text());
      var weight = (price*count*100/total_value).toFixed(2);
      $(this).text((isNaN(weight) ? 0 : weight) + "%");
    })
  },

  stocksTotalValue: function(){
    var total = 0;
    $(".j_stock_count").each(function(){
      var count = parseInt($(this).text());
      var price = parseFloat($(this).next().next().attr("data"));
      total += price*count;
    })
    return total;
  }
}


var AdjustOrder = {
  _original_basket_id: null, 

  buyStock: function(obj){
    $(".trade_type").val("OrderBuy");
    var step = $(".j_stock_est_shares").attr("step");
    $(".j_stock_est_shares").val(step).attr("min", step).attr("max", 1000000);
    this.updateTotalMoney();
    this.enableSubmitBtn();
    Amount.adjustKbdStyle($(".j_stock_est_shares"));
  },

  sellStock: function(obj){
    $(".trade_type").val("OrderSell");
    var stock_total = parseInt($(obj).attr("stock_total"));
    var input_value = stock_total>=0 ? (stock_total<step ? 0 : stock_total) : 0;
    $(".j_stock_est_shares").val(input_value);
    var step = $(".j_stock_est_shares").attr("step");
    var min = stock_total >= step ? step : 0;
    var max = stock_total>=0 ? (stock_total<step ? 0 : stock_total) : 0;
    $(".j_stock_est_shares").attr("min", min).attr("max", max);
    this.updateTotalMoney();
    this.enableSubmitBtn();
    Amount.adjustKbdStyle($(".j_stock_est_shares"));
  },

  addStockNumber: function(input_obj){
    Amount.add(input_obj);
    this.updateTotalMoney();
  },

  subStockNumber: function(input_obj){
    Amount.reduce(input_obj);
    this.updateTotalMoney();
  },

  updateTotalMoney: function(){
    var total_number = parseInt($(".j_stock_est_shares").val());
    var order_type = $("input[name='order[order_type]']").val();
    var stock_price = (order_type == "market") ? parseFloat($(".j_stock_price").first().val()) : parseFloat($("#order_limit_price").val());
    var total_money = (total_number * stock_price).toFixed(2);
    $("#order_total_money").val(total_money);
    $(".j_stock_total_money").text(accounting.formatMoney(total_money, ''));
  },

  checkOrderNewForm: function(){
    $("#btn_submit").attr("disabled", "disabled");
    $("#btn_submit").html("下单中");
    var status = AdjustOrder.checkOrderValues();
    if (status == true){
      status = AdjustOrder.ajaxCreateOrder(false);
    }
    if (status == true){
      Adjust.refreshStocksWeight();
      setTimeout("Adjust.hideFloat();", 200);
    }else{
      AdjustOrder.enableSubmitBtn();
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
          order: AdjustOrder.getOrderParams(),
          adjust_stocks: AdjustOrder.getAllStocksCount(),
          trade_type: $("#order_trade_type").val(),
          original_basket_id: AdjustOrder._original_basket_id
      },
      success: function (response) {
        if (response.error == true){
          CaishuoAlert(response.error_msg);
          status = false;
        }else{
          window.open("/orders/" + response.order_id);
          status = true;
        }
      }
    })
    return status;
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
    order_details_attributes['0'] = order_detail;
    order_params["order_details_attributes"] = order_details_attributes;
    order_params["gtd"] = $("#order_expiry").val();
    order_params["trading_account_id"] = gon.account_id;
    return order_params;
  },

  stockSizeInputEventHandle: function(){
    $(document).on("keyup", ".j_stock_est_shares", function(event){
      if (!(event.which == 37 || event.which == 39)){
        Amount.checkInputIsNumber(this);
        AdjustOrder.updateTotalMoney();
      }
    })
    $(document).on("blur", ".j_stock_est_shares", function(){
      Amount.adjustUserInputNumber(this);
      AdjustOrder.updateTotalMoney();
    })
  },

  limitPriceRadioClickHandle: function(){
    $(document).on("click", "#order_type_radio_1", function(){
      $(this).parents('.selectbox').find('input').val($(this).attr('data-value'));
      $("#order_limit_price").removeAttr("disabled").removeAttr("readonly");
      AdjustOrder.updateTotalMoney();
    })

    $(document).on("click", "#order_type_radio_2", function(){
      $(this).parents('.selectbox').find('input').val($(this).attr('data-value'));
      $("#order_limit_price").attr("disabled", "disabled").attr("readonly", "readonly");
      AdjustOrder.updateTotalMoney();
    })
    
    $(document).on("keyup", "#order_limit_price", function(){
      AdjustOrder.updateTotalMoney();
    })

    $(document).on("keyup", "#order_limit_price", function(){
      if (event.which == "37" || event.which == "39"){
        return true;
      }
      var adjusted_value = $(this).val().replace(/[^0-9\.]+/,'').replace(/[^0-9\.]+/,'');
      adjusted_value = adjusted_value == "" ? "" : adjusted_value.match(/([0-9]+.?[0-9]{0,})/)[0]
      $(this).val(adjusted_value);
    })
  },

  checkOrderValues: function(){
    var status = true;
    if (parseInt($(".j_stock_est_shares").first().val()) <= 0){
      alert("股票数量不对！");
      status = false;
    }
    
    return status;
  },

  getAllStocksCount: function(){
    var stocks = {};
    $(".themeStocks tbody tr .j_adjust_stock_id").each(function(){
      stocks[$(this).val()] = $(this).parent().find(".j_stock_count").text();
    })
    return stocks;
  }
}