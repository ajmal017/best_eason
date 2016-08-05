$(function(){
  changePaginateToAjaxLinks();
  loadBasketsTags();
  setInitialStateWhenFirstLoad();
  highlightKeywords();

  $(".j_filter_order li").on("click", function(){
    $(this).siblings().removeClass("active");
    $(this).addClass("active");
    searchBaskets(1, true);
  })
  
  $(".j_filter_tag li").on("click", function(){
    $(this).siblings().find("a").attr("class", "themes-wihte-btn");
    $(this).find("a").attr("class", "themes-blue-btn");
    searchBaskets(1, true);
    return false;
  })

  $(".j_filter_search_word").on("keyup", function(event){
    if (event.which == "13" && $.trim($(this).val()) != ""){  //enter
			var html = '<h4 class="j_lastSearch search_word" style="margin-top:20px;"><a href="javascript:" class="b_btn small">' + $(this).val() + ' <i class="icon whiteClose"></i></a></h4>'
      $(".screening-conditions").html(html);
      $(this).val("");
      searchBaskets(1, true);
      return false;
    }
  })
	
	$("#search").on('click', function () {
    if ($.trim($(this).prev().val()) != ""){
      var html = '<h4 class="j_lastSearch search_word" style="margin-top:20px;"><a href="javascript:" class="b_btn small">' + $(this).prev().val() + ' <i class="icon whiteClose"></i></a></h4>'
      $(".screening-conditions").html(html);
      $(this).prev().val("");
      searchBaskets(1, true);
      return false;
    }
	})

  $(document).on("click", ".search_word .b_btn", function(){
    $(this).parent().remove();
    searchBaskets(1, true);
  })

  $(".btn_search").on("click", function(){
    searchBaskets(1, true);
  })
  
  $(".leftBox .market a").on("click", function(){
    $(this).siblings().removeClass("active");
    $(this).addClass("active");
    searchBaskets(1, true);
    return false;
  })

  $(document).on('click', '.j_follow_basket', function(e){
    followBasket($(this).closest('li').attr('basket-id'), this);
    return false;
  })
  
  $('.j_theme_others').click(function(){
    window.location.href = '/baskets';
  })
  
  $('.noThemes').click(function(){
    window.open('/baskets/new','_blank');
  })

  //history back go
  window.onpopstate = function(event) {
    if (event.state && event.state["search"]){
      setSearchConditions(event.state["search"]);
      var page = isNaN(event.state["page"]) ? 1 : event.state["page"];
      searchBaskets(page, false);
    }
  };
})

// 每次搜索更新此version，response时对比此version，防止错乱渲染结果
var current_search_version;

//list page 搜索
function searchBaskets(page, if_reset_url){
  current_search_version = (new Date).getTime();
  var search_conditions = getSearchConditions();
  if (if_reset_url) setSearchParamsToUrl(search_conditions, page);
  $.get("/baskets.js", {search: search_conditions, page: page, version: current_search_version}, function(datas){
    
  });
}

function actionsAfterAjaxLoadedList(){
  window.scrollTo(0,0);
  changePaginateToAjaxLinks();
  loadBasketsTags();
  caishuo.adjustFooter();
  highlightKeywords();
  Translate.parseBody(document.getElementById('hasContent'));
}

//ajax load basket tags and current_user isfollow
function loadBasketsTags(){
  var basket_ids = [];
  $(".j_baskets > li").each(function(){
    basket_ids.push($(this).attr("basket-id"));
  })
  var tag_id = $(".j_filter_tag li a.themes-blue-btn").attr("data-value");
  $.get("/ajax/baskets/infos", {basket_ids: basket_ids, search_tag: tag_id}, function(response){
    var datas = response.tags;
    $.each(datas, function(index){
      var tags_div = $(".j_baskets > li[basket-id=" + datas[index][0] + "] .themeTags");
      tags_div.find("span").remove();
      $.each(datas[index][1], function(tag_index){
        var tag_html = "<span class='clarity-btn",
            data_tag_id = datas[index][1][tag_index][0];
        if ((data_tag_id.toString() == tag_id) || (data_tag_id==0 && $("div.market > a.active").attr("market") == "contest")){
          tag_html += " active";
        }
        tag_html += "'>" + datas[index][1][tag_index][1] + "</span>";
        tags_div.append(tag_html);
      })
    })

    var follow_datas = response.follows;
    $.each(follow_datas, function(index){
      var theme_item_span = $(".j_baskets > li[basket-id=" + datas[index][0] + "] .themeItem");
      if (follow_datas[index][1]){
        theme_item_span.addClass("favAdded");
      }
    })
  })
}

//搜索及排序参数实时add to url
function setSearchParamsToUrl(search_conditions, page){
  var params_str = "/baskets?";
  $.each(search_conditions, function(index){
    if (index != "" && search_conditions[index] != ""){
      params_str += "search[" + index + "]=" + search_conditions[index] + "&";
    }
  })
  changeBrowserUrl(params_str.substring(0, params_str.length-1), search_conditions, page);
}

function changeBrowserUrl(url, search_conditions, page){
  if (window.history && window.history.pushState){
    window.history.pushState({search: search_conditions, page: page}, document.title, url);
  }
}

//当baskets index初次加载时state值初始化
function setInitialStateWhenFirstLoad(){
  if (window.history && window.history.replaceState){
    var current_page = $(".pageNav .current").text()=="" ? 1 : parseInt($(".pageNav .current").text());
    window.history.replaceState({search: getSearchConditions(), page: current_page}, document.title, window.location.href);
  }
}

function changeBrowserUrlByPage(obj){
  var page;
  var current_page = parseInt($(".pageNav .current").text());
  if ($(obj).hasClass("previous_page")){
    page = current_page - 1;
  }else if($(obj).hasClass("next_page")){
    page = current_page + 1;
  }else{
    page = $(obj).text();
  }
  changeBrowserUrl($(obj).attr("href"), getSearchConditions(), page);
}

//页面加载完成后先预制搜索条件
function setSearchConditions(conditions){
  var tag_id = _pre_search_params["tag_id"];
  if (tag_id != null && tag_id != "" && tag_id != undefined){
    $tag = $(".j_filter_tag a").filter(function(){return $(this).attr("data-value") == tag_id.toString()});
    $tag.parent().siblings().find("a").attr("class", "themes-wihte-btn");
    $tag.attr("class", "themes-blue-btn");
  }
  
  if(conditions["tag"] != undefined){
    $tag = $(".j_filter_tag a[data-value=" + conditions['tag'] + "]");
    $tag.parent().siblings().find("a").attr("class", "themes-wihte-btn");
    $tag.attr("class", "themes-blue-btn");
  }
  
  if(conditions['market'] != undefined){
    $("div.market a[market=" + conditions['market'] + "]").addClass("active").siblings().removeClass("active");
  }
  
  if (conditions['search_word'] != undefined) {
    var html = '<h4 class="j_lastSearch search_word" style="margin-top:20px;"><a href="javascript:" class="b_btn small">' + conditions["search_word"] + ' <i class="icon whiteClose"></i></a></h4>';
    $(".screening-conditions").html(html);
  }
  
  if (conditions['order'] != undefined) {
    var order = $(".j_filter_order li[data-value=" + conditions['order'] + "]");
    $(order).addClass("active").siblings().removeClass("active");
    $(".dropdlst input").val(conditions['order']);
    $(".dropdlst label").text($(order).text());
  }
}

//list page 获取搜索参数
function getSearchConditions(){
  var params = {};
  params["order"] = $(".j_filter_order li.active").attr('data-value');
	params["market"] = $(".leftBox .market .active").attr('market');
  var search_word = $(".search_word:first").text().trim();
  if (search_word!="") params["search_word"] = search_word;
  params["tag"] = $(".j_filter_tag li a.themes-blue-btn").attr("data-value");
  return params;
}

function checkSearchVersion(version){
  return current_search_version == version;
}

function getKeywords(){
  var words = [];
  $(".search_word").each(function(){
    words.push($(this).text().trim());
  })
  return words;
}


function highlightKeywords(){
  $.each(getKeywords(), function(){
    highlightKeyword(this);
  })
}

function highlightKeyword(word){
  var replaced_word = '<em class="blue">' + word + '</em>';
  $(".themeItem .shadow .intro").each(function(){
    $(this).html($(this).text().replace(new RegExp(word,"ig"), replaced_word));
  })
  $(".j_baskets li .name").each(function(){
    $(this).html($(this).text().replace(new RegExp(word,"ig"), replaced_word));
  })
}

function changePaginateToAjaxLinks(){
  $(".pageNav a").attr("data-remote", "true").attr("onclick", "javascript:changeBrowserUrlByPage(this);");
}

//关注 or 取消关注
function followBasket(basket_id, obj){
  if (isLogined()){
    $.post("/ajax/baskets/" + basket_id + "/follow", {}, function(data){
      $(obj).parent('.themeItem').toggleClass('favAdded');
    });
  }else{
    openLoginDialog();
  }
}

function gotoBasket(basket_id){
  window.open("/baskets/" + basket_id);
}
