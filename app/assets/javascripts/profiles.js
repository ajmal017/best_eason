
$(function(){
  //rick
  $('.focusArea div').each(function(){
    $(this).find('span').width($(this).data().width/$('.focusArea div:eq(0)').data().width*150);
  });
  $('h3.multiselect').each(function(){
    var index = 0, $parent = $(this).parent();
    $(this).find('span').click(function(){
      index = $(this).index();
      $(this).addClass('active').siblings().removeClass();
      $parent.find('div.tabItem').eq(index).show().siblings('div.tabItem').hide();
    });
  });
  // function viewAll(obj){
  //   $(obj).closest('table').find('tbody').show();
  //   $(obj).closest('tfoot').hide();
  // }
  $('.sortcolumn').columnsortable();

  customTimeago();
  $('.timeago').timeago();
  //以上前端js
  
  $(document).on('click', ".userInfo .float-right .j_follow", function(){
    $.post("/p/"+_user_id+"/toggle_follow", {from: "header"}, function(response){
    })
  })
  
  $(document).on("click", ".viewmore.loaded", function(){
    if (!$(this).attr("data-status")) return;
    var index = ($(this).attr("data-show-num") || 10) - 1;
    if ($(this).attr("data-status") == "part"){
      $(this).attr("data-status", "all").text("查看全部").closest("table").removeClass("overload").find("tbody tr:gt("+index+")").hide();
      gotoPosition($(this).closest("table").position().top);
    }else{
      $(this).attr("data-status", "part").text("收起部分").closest("table").addClass("overload").find("tbody tr:gt("+index+")").show();
    }
  })
  
  $(".baskets .viewmore").click(function(){
    if ($(this).hasClass("loaded")) return;
    var params = {last_id: $(this).attr("data-last-id")}, 
        obj = $(this);
    if (loadedCallback($(this))){
      getDatasBy(1, "baskets", params, function(){
        $(obj).attr("data-status", "part").text("收起部分").closest("table").addClass("overload");
      });
      $(this).addClass("loaded").text("加载中......");
    }
  })
  
  $(".customs .multiselect span:eq(1)").click(function(){
    loadFollowedBaskets(this);
  })
  
  $(".customs .forstocks .viewmore").click(function(){
    if ($(this).hasClass("loaded")) return;
    var sids = [], params = {}, obj = $(this);
    $(".customs .forstocks tbody tr").each(function(){
      sids.push($(this).attr("data-id"));
    })
    params.sids = sids;
    getDatasBy(1, "followed_stocks", params, function(){
        $(obj).attr("data-status", "part").text("收起部分").closest("table").addClass("overload");
      });
    $(this).addClass("loaded").text("加载中......");
  })
  
  $(document).on("click", ".customs .tabItem:eq(1) .viewmore", function(){
    if ($(this).hasClass("loaded")) return;
    var bids = [], params = {}, obj = $(this);
    $(".customs .tabItem:eq(1) tbody tr").each(function(){
      bids.push($(this).attr("data-id"));
    })
    params.bids = bids;
    getDatasBy(1, "followed_baskets", params, function(){
        $(obj).attr("data-status", "part").text("收起部分").closest("table").addClass("overload");
      });
    $(this).addClass("loaded").text("加载中......");
  })
  
  $("#myFocusOn, #FocusOnMe, #bothFocus").click(function(){
    if (loadedCallback($(this))){
      var index = $(this).index(),
          tabItem = $(".combines .tabItem:eq(" + index + ")");
      setLoading($(tabItem).find(".loadMore"));
      getDatasBy(1, tabItem.attr("data-path"));
    }
  })
  
  $(document).on("click", ".combines .focususer .loadMore", function(){
    var tab_item = $(this).closest(".tabItem"),
        page = tab_item.attr("next_page"),
        path = tab_item.attr("data-path");
    setLoading($(tab_item).find(".loadMore"));
    getDatasBy(page, path);
  })
  
  $(document).on("click", ".forstocks tr .focus", function(){
    var obj = $(this), stock_id = obj.parent().parent().attr("data-id");
    $.post("/ajax/stocks/"+ stock_id +"/follow_or_unfollow", {}, function(response){
      if (response.followed == true){
        obj.addClass("active");
      }else{
        obj.removeClass("active");
      }
    })
  })
  
  $(document).on("click", ".customs .tabItem:eq(1) .focus, .baskets tr .focus", function(){
    var obj = $(this), basket_id = obj.parent().parent().attr("data-id");
    $.post("/ajax/baskets/"+ basket_id +"/follow", {}, function(response){
      if (response.followed == true){
        obj.addClass("active");
      }else{
        obj.removeClass("active");
      }
    })
  })
  
  $(document).on("click", ".j_follow", function(){
    var obj = $(this), section_obj = obj.closest("section"),
        user_id = section_obj.attr("user-id");
    if (user_id == undefined) return;
    $.post("/p/"+user_id+"/toggle_follow", {}, function(response){})
  })
})

function loadedCallback(obj){
  if ($(obj).attr("loaded") == "true") return false;
  $(obj).attr("loaded", "true");
  return true;
}

function setLoading(obj){
  $(obj).find("a").hide();
  $(obj).find("div").show();
}

function loadFollowedBaskets(obj){
  if (loadedCallback(obj)){
    $.get("/p/" + _user_id + "/followed_baskets.js", {}, function(){});
  }
}

function getDatasBy(page, path, params, callback){
  params = params || {};
  params.page = page || 1;
  callback = callback || function(){};
  $.get("/p/" + _user_id + "/" + path + ".js", params, function(){ callback(); });
}

function profileGotoPosition(id){
  $(id).trigger("click");
  gotoPosition(id);
}

function customTimeago(){
  $.timeago.settings.strings.suffixAgo = "";
  $(".timeago_c").timeago();
  $.timeago.settings.strings.suffixAgo = "前";
}