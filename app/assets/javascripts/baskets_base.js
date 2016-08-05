$(function(){
  $(".stock_reason").on("keyup", function(){
    showStockReasonLength(this);
  })

  $('.themeStocks.baseketPie').sectorPie(weights_data);
  
  $('.themeStocks.baseketPie tfoot .scrollBar').slider({
      range:'min',
      min:0,
      max:1000,
      value:0,
      disabled:true
  }).slider("value", weights_data.cash * 1000);
})


function showStockReasonLength(obj){
  $(obj).parent().find(".error").remove();
  if ($(obj).val().length > 150){
    var stock_reason_error_msg = "<span class='error plus'>最多150个字。（已超出" + ($(obj).val().length-150) + "字）</span>";
    $(obj).after(stock_reason_error_msg);
  }
}

function checkNewBasketSecondStep(){
  var status = true;
  $(".stock_reason").each(function(){
    showStockReasonLength(this);
    if ($(this).val().length > 150){
      status = false;
    }
  })
  return status;
}

//当在第二步点击上一步时，改变form的action、去掉onsubmit，然后提交到form数据到新的action
function previousStepAction(btn_obj, basket_id){
  var update_url = "/baskets/" + basket_id + "/update_attrs?step=2";
  var form = $(btn_obj).closest("form");
  $(form).attr("action", update_url);
  // $(form).removeAttr("onsubmit");
  $(form).submit();
}
