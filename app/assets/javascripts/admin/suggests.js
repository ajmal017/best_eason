var Suggest = {
  autocompleteHandle: function(){
    $("#symbolSearch").autocomplete({
      source: function( request, response ) {
        $.ajax({
          url: "/ajax/stocks/search",
          dataType: "json",
          data: {
            term: request.term
          },
          success: function( data ) {
            response( data.stocks );
          }
        });
      },
      minLength: 1,
      select: function( event, ui ) {
        if (!Suggest.checkSymbolExist(ui.item.symbol)){
          Suggest.suggestStock(ui.item.stock_id);
        }
      }
    }).autocomplete( "instance" )._renderItem = function( ul, item ) {
      return $( "<li stock_id='" + item.stock_id + "'>" )
        .append( item.symbol + " (" + item.company_name + ")" )
				.append( Suggest.checkSymbolExist(item.symbol) ? "-- 已添加" : "" )
        .appendTo( ul );
    };
  },
	
  checkSymbolExist: function(symbol){
    return $(".table-striped tbody tr").filter(function(){ return $(this).find(".j_stock_symbol").text() == symbol}).length > 0
  },
	
	suggestStock: function (stock_id) {
    $.post("/ajax/stocks/" + stock_id + "/suggest_render", { suggest_stock_id: suggest_stock_id }, function(response){
      eval(response);
    })
	},
	
	unSuggestStock: function (stock_id, obj) {
    $.post("/ajax/stocks/" + stock_id + "/unsuggest", { suggest_stock_id: suggest_stock_id } )
    $(obj).parent().parent().remove();
	}
}