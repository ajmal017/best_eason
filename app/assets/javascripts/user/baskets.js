function getPageByPageLink(page_link_obj){
  var page;
  var current_page = parseInt($(page_link_obj).parent().find('.current').text());

  if ($(page_link_obj).hasClass("previous_page")){
    page = parseInt(current_page) - 1;
  } else if ($(page_link_obj).hasClass("next_page")){
    page = parseInt(current_page) + 1;
  }else{
    page = $(page_link_obj).text();
  }

  return page;
}

//我的主题
var Baskets = {
  themeTypeClickHandle: function(){
    $("#j_baskets_content .asSwitchBtn li").on("click", function(){
      $(this).siblings().removeClass("active").end().addClass("active");
    })
  },

  showFollowedBaskets: function(page){
    this.clearBaskets();
    this.clearPagination();
    $.get("/user/baskets/followed", {page: page})
  },

  changeFollowedBasketsPage: function(link_obj){
    this.showFollowedBaskets(getPageByPageLink(link_obj));
  },

  changePaginateToAjaxGetFollowedBaskets: function(){
    $(".pageNav a").attr("href", "javascript:void(0);");
    $(".pageNav a").attr("onclick", "javascript:Baskets.changeFollowedBasketsPage(this);");
  },

  showCustomizedBaskets: function(page){
    this.clearBaskets();
    this.clearPagination();
    $.get("/user/baskets/customized", {page: page})
  },

  changeCustomizedBasketsPage: function(link_obj){
    this.showCustomizedBaskets(getPageByPageLink(link_obj));
  },

  changePaginateToAjaxGetCustomizedBaskets: function(){
    $(".pageNav a").attr("href", "javascript:void(0);");
    $(".pageNav a").attr("onclick", "javascript:Baskets.changeCustomizedBasketsPage(this);");
  },

  showCreatedBaskets: function(page){
    this.clearBaskets();
    this.clearPagination();
    $.get("/user/baskets/created", {page: page})
  },

  changeCreatedBasketsPage: function(link_obj){
    this.showCreatedBaskets(getPageByPageLink(link_obj));
  },

  changePaginateToAjaxGetCreatedBaskets: function(){
    $(".pageNav a").attr("href", "javascript:void(0);");
    $(".pageNav a").attr("onclick", "javascript:Baskets.changeCreatedBasketsPage(this);");
  },

  clearBaskets: function(){
    $(".my-theme .baskets").html("");
  },

  clearPagination: function(){
    $("#page_paginate").html("");
  },

  deploy: function(basket_id){
    $.post("/ajax/baskets/" + basket_id + "/deploy");
  },

  archive: function(basket_id, obj){
    $.post("/ajax/baskets/" + basket_id + "/archive", {}, function(data){
      if(data){
        $(obj).parents('table').next('.break').remove().end().remove();
        $.alert({text: '归档成功'});
      }else{
        $.alert({text: '归档失败!!!'});
      }
    })
  },

  showArchivedList: function(){
    $.get("/user/baskets/archived")
  },

  deleteBasket: function(basket_id, del_obj){
    $.confirm({text: '您确定要删除吗？', confirm: function(){
      $.post("/ajax/baskets/" + basket_id + "/destroy_draft");
      $(del_obj).closest("table").remove();
    }})
  },

  unfollowBasket: function(basket_id, obj){
    var text = "你确认取消关注 " + $(obj).attr('basket-title') + "?";
    CaishuoConfirm(text, function(){
      $.post("/ajax/baskets/" + basket_id + "/follow", {}, function(data){
        if (data.followed != true){
          $(obj).parent().remove();
          CaishuoDialog.close();
        }else{
          CaishuoAlert('取消关注失败!!!');
        }
        return true;
      });
      return true;
    })
  },

  resizeWindow: function(){
    $(window).trigger('resize');
  }, 

  hideFloat: function(){
    $('#FloatWindow').fadeOut();
    $('#FloatWindow .FloatContent').slideUp();
    $('body').removeClass('fixed');
  },

  // 归档恢复
  recover: function(basket_id, obj){
    $.post("/ajax/baskets/" + basket_id + "/recover", {}, function(data){
      $(obj).parents('tr').remove();
    })
  }

}

