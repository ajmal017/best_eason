

function loadBasketPositions(open_btn){
  var basket_id = $(open_btn).attr("data-basket-id"), 
      loaded = $(open_btn).attr("data-loaded");
  
  if (loaded != "true"){
    $(open_btn).attr("data-loaded", "true");
    var account_id = $(open_btn).parents("table.holding-box").attr("account-id");
    $.get("/accounts/"+account_id+"/positions/basket_positions", {basket_id: basket_id})
  }
}

function setAccountDetails(account_id, details_html){
  var account_h3 = $("h3[account-id="+account_id+"]");
  account_h3.parent().siblings("table").remove();
  account_h3.parent().after(details_html);
  setColSet();
}

function loadingAccountsProfits(){
  $.get("/user/positions/profits", {}, function(datas){
    $.each(datas, function(index){
      var data = datas[index], 
          unit = data.cash_unit,
          item = $(".content[account-id="+data.id+"] > div.holding-status"),
          item_total_profit = item.find("span:eq(0)"),
          item_today_profit = item.find("span:eq(1)"),
          item_usable_cash = item.find("span:eq(2)"),
          item_total = item.find("span:eq(3)");
      item_total.find("strong").text(accounting.formatMoney(data.total_property, unit));
      item_today_profit.find("strong").addClass(moneyClass(data.today_profit)).text(formatMoney(data.today_profit, unit));
      item_total_profit.find("strong").addClass(moneyClass(data.total_profit)).text(formatMoney(data.total_profit, unit));
      item_usable_cash.find("strong").text(formatMoney(data.usable_cash, unit));
      
    })
  })
}

function moneyClass(value){
  return value>=0 ? "plus" : "mins";
}

//仅限显示涨跌的使用
function formatMoney(value, unit){
  var str = value >= 0 ? "" : "-";
  str += accounting.formatMoney(Math.abs(value), unit);
  return str;
}

function refreshPositions(account_id, refresh_obj){
  if ($(refresh_obj).hasClass("load")) return;

  if (account_id != ""){
    $(refresh_obj).addClass("load");
    $.post("/accounts/"+account_id+"/refresh_positions", {}, function(response){
      if ($('.holding-status h3[account-id="'+account_id+'"]').hasClass("close")){
        $(refresh_obj).removeClass("load");
      }else{
        $.get("/accounts/"+account_id+"/positions", {}, function(){
          $(refresh_obj).removeClass("load");
        });
      }
    })
  }
}


//------

$(window).bind('scroll', function () {
    var headTop = $('#navCanFloat').offset().top;
    $('#navCanFloat').toggleClass('navFloat', $(window).scrollTop() > headTop);
});


$(function(){
    loadingAccountsProfits();

    $('.holding-status h3').click(function(){
      if($(this).attr('class') !== 'close'){
        $(this).parent().siblings('table').find('.stocks').hide();
        $(this).parent().siblings('table').find('.open').removeClass('close');
      }
      $(this).parent().siblings('.position_list').toggle();
      $(this).toggleClass('close');

      if ($(this).attr("loaded") !== "true"){
        $(this).attr("loaded", "true");
        $.get("/accounts/"+$(this).attr("account-id")+"/positions");
      }
      caishuo.adjustFooter();
    });
  
    $(document).on('click', '.open', function(){
      $(this).toggleClass('close');
      $(this).parent().parent().nextUntil('.baskets').toggle();
      loadBasketPositions($(this));
    });

    colSet("col1")
    $('.asSwitchBtn li').click(function(){
    var num = $(this).index()+1;
      $('.asSwitchBtn li').removeClass('active');
      $(this).addClass('active');
    colSet("col"+ num)
    })
    
    sortColumn();

    $(".content").each(function(){
      Account.refreshCash($(this).attr("account-id"));
    })

    $(document).on("click", ".stock_more", function(){
      if ($(this).attr("status") == "loading") return;
      $(this).attr("status", "loading");
      var account_id = $(this).closest("table").attr("account-id"),
          page = $(this).attr("data-next-page"),
          btn = $(this);

      $.get("/accounts/"+account_id+"/positions/stocks", {page: page}, function(){
        $(btn).attr("status", "loaded");
        colSet("col1");
        $('.sortcolumn').columnsor();
        $(".holding-top .active").trigger("click");
      })
    })
});

function colSet(name){
  var arr = [];
  $('.holding_a thead tr').children().each(function(){
    arr.push($(this).hasClass(name))
  })

  $('.holding_a tr').each(function(){
    var asd= $(this);
    $.each(arr,function(i){
      asd.children().eq(i).toggle(arr[i]);
    });
  })
}

function setColSet(){
  colSet("col"+ ($('.asSwitchBtn li.active').index()+1));
}



$.fn.columnsor = function() {
  return $(this).each(function() {
      var $table = $(this).closest('table'), $tbody = $table.find('tbody');$sbody = $table.find('.motif');
      $tbody.children().hover(function(){
          $(this).addClass('sortcell');
      },function(){
          $(this).removeClass('sortcell');
      });
      $tbody.each(function(){
          $(this).children().each(function(i){
              $(this).attr('data-posi',i);
          })
      });

      $sbody.each(function(i){
          $(this).attr('data-posi2',i);
      });

      function sort_reset(){
          $tbody.each(function(){
              var _this = this;
              $(this).children().each(function(i){
                  $(_this).find('[data-posi='+i+']').appendTo(_this);
              });
          });

          $sbody.each(function(i){
              var _this = this;
              $(_this).find('[data-posi2='+i+']').appendTo(_this);
          });
      }
      function sort_down(obj){
          sort_reset();
          $(obj).addClass('sortdown');
          var index = $(obj).parent().index();
          $tbody.each(function(){
              var arr = [], _this=this;
              $(this).children().each(function(i){
                  var $cell = $(this).children().eq(index), text="";
                  if ($cell.attr('data-sort') != undefined){
                      text=$cell.attr('data-sort');
                  }else{
                      text=$cell.text().replace(/\s+/g,' ').replace(/^\s+|\s+$/,'').split(' ')[0];
                  }
                  arr[i] = {"sort":i, "text":text};
              });
              arr.sort(function(a,b){
                  var p=a.text,n=b.text;
                  if (/^\w+\$|\$?[+|-]?[\d+|,]\.?\d?\%?$/.test(p) && /^\w+\$|\$?[+|-]?[\d+|,]\.?\d?\%?$/.test(n)){
                      return parseFloat(n.replace(/\w+\$|\$|\,|\%/, '')) - parseFloat(p.replace(/\w+\$|\$|\,|\%/, ''));
                  }
                  return n.localeCompare(p);
              });
              for (var i=0,len=$(this).children().length;i<len;i++){
                  var $item = $(_this).find('[data-posi="'+arr[i].sort+'"]');
                  $item.children().eq(index).addClass('sortcell')
                  $item.appendTo(_this);
              }
              if($(this).hasClass('motif')){
                $(_this).find('[data-posi="0"]').prependTo(_this);
              }
          });
      }
      function sort_up(obj){ 
          sort_down(obj);
          $(obj).toggleClass('sortup sortdown')
          $tbody.each(function(){ 
              var _this = this;
              $(this).children().each(function(){
                  $(this).prependTo(_this);
              });
              if($(this).hasClass('motif')){
                $(_this).find('[data-posi="0"]').prependTo(_this);
              }
          });
      }
      $(this).click(function(){
          if ($(this).hasClass('sortdown')){
              // 倒序 -> 正序
              sort_up(this);
          }else if ($(this).hasClass('sortup')){
              // 正序 -> 无序
              sort_reset();
              $table.find('.sortcell').removeClass('sortcell');
              $table.find('.sortcolumn').removeClass('sortup sortdown');
          }else{
              $table.find('.sortcell').removeClass('sortcell');
              $table.find('.sortcolumn').removeClass('sortup sortdown');
              // 无序 -> 倒序
              sort_down(this);
          }
      });
  });
};

// table 排序
$('.sortcolumn').columnsor();
