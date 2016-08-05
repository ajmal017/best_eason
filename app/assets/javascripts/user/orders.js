$(function(){
  $(".order_details").on("click", function(){
    var order_id = $(this).parent().attr("data-order-id");
    $.get("/user/orders/"+order_id+"/details");
  })

  $('.cancel').click(function(){
    var id = $(this).parent().parent().parent().attr("data-id"),
        account_id = $(this).parent().parent().parent().attr("account-id"),
        cancel_btn = $(this);
    Account.checkLogined(account_id, false, function(){
      CaishuoDialog.open({theme:'confirm',title:'取消订单',content:'您确定取消该订单么？',callback:function(){
        $.post("/ajax/orders/"+id+"/cancel", {account_id: account_id}, function(response){
          if (response.status){
            $(".trading[data-id=" + id + "] tr:eq(1) td:eq(6)").html(OrderList.item_status("取消中"));
            $(cancel_btn).after("<em>取消中</em>").remove();
            CaishuoDialog.close();
          }
        })
      }})
    })
  })

  $("#account li").on("click", function(){
    var url = "/accounts/orders?q[account]=" + $(this).attr("data-value");
    window.location.href = encodeURI(url);
  })

  $("#product_type li, #market li, #trade_type li, #status li").on("click", function(){
    gotoSearchUrl();
  })

  $(".j_filter_search_word").on("keyup", function(event){
    if (event.which == "13"){
      gotoSearchUrl();
    }
  })

  $("#search").on("click", function(){
    gotoSearchUrl();
  })

  $("#account li").each(function(){
    Account.refreshCash($(this).attr("data-value"));
  })

  setInterval("OrderList.refreshExecutingOrders()", 3000);
})


function gotoSearchUrl(){
  var account = $("#account .active").attr("data-value"), 
      query_word = $(".j_filter_search_word").val(),
      url = "/accounts/orders?q[account]" + "=" + account + "&q[query_word]=" + query_word,
      fields = ["product_type", "market", "trade_type", "status"];
  $.each(fields, function(index){
    url += "&q[" + fields[index] + "]=" + $("#"+fields[index]+" .active").attr("data-value");
  })
  window.location.href = encodeURI(url);
}


OrderList = {
  refreshExecutingOrders: function(){
    $.get("/ajax/orders/orders_infos?"+(new Date()).getTime(), {order_ids: this.getExecutingOrderIds()}, function(datas){
      $.each(datas, function(index){
        OrderList.renderItem(datas[index]);
      })
    })
  },

  renderItem: function(data){
    var order_item = $(".trading[data-id=" + data.id + "] tr:eq(1)"),
        trading_amount = order_item.find("td:eq(3)"),
        avg_html = "";

    trading_amount.text(data.real_shares + "/" + trading_amount.text().split("/")[1]);
    order_item.find("td:eq(6)").html(OrderList.item_status(data.status_name));
    if (data.can_cancel != true || data.status_name == "交易取消"){
      order_item.find("td:last a:first").nextAll().remove();
    };

    avg_html += data.avg_cost == "--" ? "--" : accounting.formatMoney(data.avg_cost, data.currency_unit);
    avg_html += "<br/>" + data.currency_unit;
    avg_html += data.real_cost ? accounting.formatMoney(data.real_cost, '') : '0.00';
    order_item.find("td:eq(4)").html(avg_html);
  },

  item_status: function (c_status) {
    var html = '';
    if(c_status == '执行中'){
      html += "<em class='text-blue'>" + c_status + "</em>";
    }else if(["取消中", "交易取消", "交易失效"].indexOf(c_status) >= 0){
      html += "<em class='plus'>" + c_status + "</em>"
    }else{
      html += c_status;
    }
    return html;
  },

  getExecutingOrderIds: function(){
    var ids_str = "";
    $("tbody[class=trading]").each(function(){
      ids_str += $(this).attr("data-id") + ",";
    })
    return ids_str;
  }
}

function refreshOrders(refresh_obj){
  if ($(refresh_obj).hasClass("load")) return;

  var account_id = $("#account").parent().find("input:eq(0)").val();
  if (account_id != ""){
    $(refresh_obj).addClass("load");
    $.post("/accounts/"+account_id+"/refresh_orders", {}, function(response){
      $(refresh_obj).removeClass("load");
      OrderList.refreshExecutingOrders();
      window.location.reload();
    })
  }
}