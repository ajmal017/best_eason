$(function(){
  // $("#topic_notes").on("keyup", function(){
  //   $(this).parent().find("span").remove();
  //   if ($(this).val().length > 140){
  //     var stock_reason_error_msg = "<span style='color:red;'>最多140个字。（已超出" + ($(this).val().length-140) + "字）</span>";
  //     $(this).after(stock_reason_error_msg);
  //   }
  // })

  // iframe 不刷新提交文件
  $("#real_avatar, #real_avatar_2").change(function(){
    var currentForm = $(this).parents("form");
    if($("iframe[name='curform']").length > 0){
      var thisIframe = $("iframe[name='curform']");
    }else{
      var thisIframe = $("<iframe style='opacity:0;_filter:alpha(opacity=0)'></iframe>").attr("name",currentForm.attr("target"));
    }
  
    $(currentForm).after(thisIframe);
    $(currentForm).submit();
    $("#real_avatar, #real_avatar_2").val("");
    showCropModal();
  });

  $("#topic_stock_search").autocomplete({
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
      $.post("/admin/topics/" + _topic_id + "/add_stock", {stock_id: ui.item.stock_id}, function(){
        relatedBasketsByStocks();
      })
    }
  }).autocomplete( "instance" )._renderItem = function( ul, item ) {
    return $( "<li stock_id='" + item.stock_id + "'>" )
      .append( item.symbol + " (" + item.company_name + ")" )
      .appendTo( ul );
  };

  relatedBasketsByStocks();

  $( ".sortable" ).sortable({
    items: "tr",
    placeholder: "ui-state-highlight"
  });
  $( ".sortable" ).disableSelection();

})


function checkTopicForm(){
  $("#topic_title").css("border-color", "");
  // $("#topic_notes").css("border-color", "");
  var status = true;

  if (TextCheck($("#topic_title").val()) > 10 || TextCheck($("#topic_title").val()) == 0){
    $("#topic_title").css("border-color", "red");
    status = false;
  }
  // if ($("#topic_notes").val().length > 140 || $("#topic_notes").val().length == 0){
  //   $("#topic_notes").css("border-color", "red");
  //   status = false;
  // }
  return status;
}

//20s
function autoSaveBasicInfos(){
  if (checkTopicForm()){
    var topic_id = $("#topic_id").val(), topic_params = {};
    if ($("#topic_market").val()) topic_params["market"] = $("#topic_market").val();
    topic_params["title"] = $("#topic_title").val();
    topic_params["sub_title"] = $("#topic_sub_title").val();
    topic_params["summary"] = $("#topic_summary").val();
    editor.sync()
    topic_params["notes"] = $("#richeditor").val();

    if (topic_id == ""){
      $.post("/admin/topics.json", {topic: topic_params}, function(response){
        if (response.status){
          $("#topic_form").attr("action", "/admin/topics/"+response.topic_id);
          $("#topic_id").val(response.topic_id);
          $("#topic_form").prepend("<input type='hidden' name='_method' value='patch'>");
          if (window.history){
            window.history.pushState({}, document.title, "/admin/topics/"+response.topic_id+"/edit");
          }
        }
      })
    }else{
      $.post("/admin/topics/"+topic_id+".json", {_method: "patch", topic: topic_params}, function(response){
        
      })
    }
  }
}

function TextCheck(val) {
  var text = val.replace(/\s+/g,'');
  var n = 0;
  for(var i=0;i<text.length;i++)
  {
    if(text.charCodeAt(i)<128) {
      n++;
    } else {
      n+=2;
    }
  }
  return n;
}

function fetchNewsByUrl(){
  var url = $.trim($("#topic_news_url").val());
  if(url == ""){
    alert("请填写url！");
  }else{
    $.post("/admin/topics/" + _topic_id + "/topic_news", {url: url}, function(){})
  }
}

function autoSaveNewsTitle(obj){
  var news_id = $(obj).parent().parent().attr("data-id");
  var title = $.trim($(obj).val());
  if (title != ""){
    $.post("/admin/topics/" + _topic_id + "/topic_news/" + news_id, {_method: 'put', title: title}, function(response){
      if(response.status == false){
        alert("标题保存出错!");
      }
    });
  }else{
    alert("标题不能为空！");
  }
}

function autoSaveNewsSource(obj){
  var news_id = $(obj).parent().parent().attr("data-id");
  var source = $.trim($(obj).val());
  if (source != ""){
    $.post("/admin/topics/" + _topic_id + "/topic_news/" + news_id, {_method: "put", source: source}, function(response){
      if(response.status == false){
        alert("来源保存出错!");
      }
    });
  }else{
    alert("来源不能为空！");
  }
}

function destroyTopicNews(obj){
  var topic_news_id = $(obj).parent().parent().attr("data-id");
  $.post("/admin/topics/"+_topic_id+"/topic_news/"+topic_news_id, {_method: 'delete'}, function(response){
    if(response.status){
      $(obj).parent().parent().remove();
    }else{
      alert("删除出错！");
    }
  })
}

function addNotesToTopicStock(obj){
  var html = "<textarea cols='45' rows='3'>" + $(obj).parent().parent().attr("data-notes");
  html += "</textarea><input type='button' value='保存' onclick='javascript:saveTopicStockNotes(this, ";
  html += $(obj).parent().parent().attr("data-id") + ");' style='margin: 5px;'></input>"
  open_dialog("填写入选理由", html);
}

function saveTopicStockNotes(obj, topic_stock_id){
  var notes = $(obj).prev().val();
  $.post("/admin/topics/"+_topic_id+"/topic_stocks/"+topic_stock_id, {_method: 'put', notes: notes}, function(response){
    if (response.status){
      $("#topic_stocks_table tbody tr").filter(function(){return $(this).attr("data-id") == topic_stock_id }).attr("data-notes", notes);
      $(obj).after("<span style='color:red;'>保存成功！</span>");
    }else{
      alert("保存出错！");
    }
  })
}

function destroyTopicStock(obj){
  var topic_stock_id = $(obj).parent().parent().attr("data-id");
  $.post("/admin/topics/"+_topic_id+"/topic_stocks/"+topic_stock_id, {_method: 'delete'}, function(response){
    if(response.status){
      $(obj).parent().parent().remove();
      relatedBasketsByStocks();
    }else{
      alert("删除出错！");
    }
  })
}

function setStockVisible(obj){
  var topic_stock_id = $(obj).parent().parent().attr("data-id");
  var visible = $(obj).is(":checked");
  $.post("/admin/topics/"+_topic_id+"/topic_stocks/"+topic_stock_id, {_method: 'put', visible: visible}, function(response){

  })
}

function relatedBasketsByStocks(){
  $("#topic_baskets_table tbody tr").remove();
  var stock_ids = getAllStockIds();
  if(stock_ids.length > 0){
    $.get("/admin/topics/"+_topic_id+"/baskets", function(datas){
      $.each(datas, function(){
        var html = "<tr data-id='" + this.id + "'><td><input type='checkbox' class='cbx_basket' onclick='selectBasket(this);'/></td>";
        html += "<td><a target='_blank' href='/baskets/" + this.id + "'>" + this.title + "</a></td>";
        html += "<td>" + this.count + "</td>";
        html += "<td>" + this.author + "</td>";
        html += "<td>" + this.created_at + "</td></tr>";
        $("#topic_baskets_table tbody").append(html);
      })

      checkSelectedBaskets();
    })
  }
}

function checkSelectedBaskets(){
  var basket_ids = _basket_ids.split(",");
  $(".cbx_basket").each(function(){
    var basket_id = $(this).parent().parent().attr("data-id");
    if(basket_ids.indexOf(basket_id) >= 0){
      $(this).attr("checked", "checked");
    }
  })
}

function selectBasket(obj){
  var checked_inputs = $(".cbx_basket:checked");
  if (checked_inputs.length > 4){
    alert("最多选择4个组合！");
    $(obj).removeAttr("checked");
  }else{
    var basket_ids = [];
    checked_inputs.each(function(){
      basket_ids.push($(this).parent().parent().attr("data-id"));
    })
    $.post("/admin/topics/"+_topic_id+"/update_baskets", {basket_ids: basket_ids}, function(){
      _basket_ids = basket_ids.join(",");
    })
  }
}

function getAllStockIds(){
  var ids = [];
  $("#topic_stocks_table tbody tr").each(function(){
    ids.push($(this).attr("data-stock-id"));
  })
  return ids;
}

function saveNewsPositions(){
  var topic_news_ids = [];
  $("#topic_news_table tbody tr").each(function(){
    topic_news_ids.push($(this).attr("data-id"));
  })
  updatePositions("TopicNews", topic_news_ids);
}

function saveStocksPositions(){
  var topic_stocks_ids = [];
  $("#topic_stocks_table tbody tr").each(function(){
    topic_stocks_ids.push($(this).attr("data-id"));
  })
  updatePositions("TopicStock", topic_stocks_ids);
}

function updatePositions(class_name, ids){
  if(ids.length > 0){
    $.post("/admin/topics/positions", {class_name: class_name, ids: ids}, function(res){
      if(res.status){
        alert("排序保存成功！");
      }
    });
  }
}

function updateTopicArticles(){
  $.post("/admin/topics/"+_topic_id+"/reset_articles", {}, function(){
    alert("更新成功！");
  })
}

function saveArticlesPositions(){
  var topic_article_ids = [];
  $("#topic_articles_list tr").each(function(){
    topic_article_ids.push($(this).attr("data-id"));
  })
  updatePositions("TopicArticle", topic_article_ids);
}

function setArticleVisible(obj){
  var topic_article_id = $(obj).parent().parent().attr("data-id");
  var visible = $(obj).is(":checked");
  $.post("/admin/topics/"+_topic_id+"/topic_articles/"+topic_article_id, {_method: 'put', visible: visible})
}

//ajax upload pic functions

// 显示裁剪框
var showCropModal = function(){
  $('#FloatWindow').fadeIn();
  $('#FloatWindow .FloatContent').slideDown();
  $('body').addClass('fixed');
}

function hideCropModal(){
  $("iframe").remove();
  $('#FloatWindow').fadeOut();
  $('#FloatWindow .FloatContent').slideUp();
  $('body').removeClass('fixed');
}

// 设置裁剪坐标
var updateCoordinate = function(c){
  if (parseInt(c.w) > 0){
    $('#topic_crop_x').val(c.x);
    $('#topic_crop_y').val(c.y);
    $('#topic_crop_w').val(c.w);
    $('#topic_crop_h').val(c.h);
  }
}

var setFloatWindowAttrs = function(width, form_url){
  $(".FloatContent").css("width", width);
  $("#FloatWindow form").attr("action", form_url);
}

// @Jcrop 初始化

var JcropInit = function(y_div_x, aspect_ratio){
  var jcrop_api, boundx, boundy;

  $('#cropbox').Jcrop({
    onChange: updateCoordinate,
    onSelect: updateCoordinate,
    aspectRatio: aspect_ratio
  },function(){
    var bounds = this.getBounds();
    boundx = bounds[0];
    boundy = bounds[1];
    jcrop_api = this;
    if(boundx >= boundy/y_div_x){
      bound_length = boundy - 30;
      pointer_x = (boundx - bound_length/y_div_x) / 2;
      jcrop_api.setSelect([pointer_x, 15, bound_length/y_div_x + pointer_x, bound_length + 15]);
    }else{
      bound_length = boundx - 30;
      pointer_y = (boundy - bound_length*y_div_x) / 2;
      jcrop_api.setSelect([15, pointer_y, bound_length + 15, bound_length*y_div_x + pointer_y]);
    }
  });
};
