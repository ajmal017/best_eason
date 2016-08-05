$(function() {
  $('.datetimepicker').datepicker({
    autoclose: true,
    language: 'ZH',
    pickTime: false,
    minView: 'month',
    format: 'yyyy-mm-dd'
  });
  
  // 省份 城市
  $('.current_province').change(function(){
    province_id = $('.current_province').val();
    if(province_id.length == 0){
      province_id = 0;
    }
    $.getScript('/ajax/region/cities?province_id='+province_id);
  });

  initDescriptionEditor("richeditor");

  //批量删除规范
  $('.top_tree').click(function(){
    $('.bottom_tree').prop('checked','checked');
    if(this.checked){
      $('.bottom_tree').prop("checked",true)
    }else{
      $('.bottom_tree').prop("checked",false)
    }
  });
  $('.bottom_tree').click(function(){
    var count = 0;
    var checkArry = $('.bottom_tree');
    for (var i = 0; i < checkArry.length; i++) { 
      if(checkArry[i].checked == true){
        count++;
      }
    }
    if(count == checkArry.length){
      $('.top_tree').prop("checked",true)
    }else{
      $('.top_tree').prop("checked",false)
    }
  });

  $("#stock_search").autocomplete({
    //得到满足条件的stock
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
    select: function( event, ui ) {
    var stocks_str = $("#stocks_search_ids").val()
    if (stocks_str.indexOf(ui.item.stock_id) < 0){
      if (stocks_str == ""){
          $("#prompt").remove();
        $("#stocks_search_ids").val(stocks_str + ui.item.stock_id)
        }else{
          $("#stocks_search_ids").val(stocks_str += "," + ui.item.stock_id)
        }
        $("#new_stock").append("<ul id='stock_"+ui.item.stock_id+"'><li id='stock' style='float:left;'>"+ui.item.symbol+'('+ui.item.company_name+')'+"<a href='javascript:' style='color:red;' onclick='destroyStock("+ui.item.stock_id+")'>X</a></li></ul>")
      } else {
        alert("此股票已存在不能重复添加！")
      }
    }
    //显示满足条件的stock
  }).autocomplete( "instance" )._renderItem = function( ul, item ) {
    return $( "<li stock_id='" + item.stock_id + "'>" )
      .append(item.stock_id + "&nbsp;&nbsp;&nbsp;" + item.symbol + "&nbsp;&nbsp;&nbsp;" + item.company_name)
      .appendTo( ul );
  };

  //select2() 用户Name
  $(".select_user").select2({
    placeholder: "请输入用户名",
    ajax: {
      url: "/ajax/global/search_user",
      dataType: 'json',
      delay: 300,
      data: function(params){
        return {
          q: params.term
        };
      },
      processResults: function (data, page) {
        return {
          results: data.users
        };
      }
    },
    templateResult: formatUser, //显示查询结果
    templateSelection: formatUserSelection, //显示选中的对象
    escapeMarkup: function (markup) { return markup; }
  });
  function formatUser (user) {
    if (user.loading) return user.text; // 返回正在加载数据
    var markup = "<div style='float:center;color:#4F4F4F;'>"+user.username+"</div> " 
    return markup;
  }
  function formatUserSelection (sender) {
    if (sender.username == undefined){
      return "请输入用户名";
    } else {
      return sender.username;
    }
  }

  //select2() 股票Symbol
  $(".select_stock_by_symbol").select2({
    placeholder: "请输入股票代码",
    ajax: {
      url: "/ajax/global/search_stock",
      dataType: 'json',
      delay: 300,
      data: function(params){
        return {
          q: params.term
        };
      },
      processResults: function (data, page) {
        return {
          results: data.stocks
        };
      }
    },
    templateResult: formatStock, //显示查询结果
    templateSelection: formatStockSelection, //显示选中的对象
    escapeMarkup: function (markup) { return markup; }
  });
  function formatStock (stock) {
    if (stock.loading) return stock.text; // 返回正在加载数据
    var markup = "<div style='float:center;color:#4F4F4F;'>"+stock.name+"</div> " 
    return markup;
  }
  function formatStockSelection (stock) {
    if (stock.name == undefined){
      return "请输入股票Name";
    } else {
      return stock.name;
    }
  }

});



//autocomplete
function destroyStock(id){
  var stock_ids = $("#stocks_search_ids").val()
  $("#stock_"+id).remove();
  new_ids = []
  var all_ids = stock_ids.split(",")
  for(var i in all_ids){
    if (all_ids[i] != id){
      new_ids.push(all_ids[i])
    }
  }
  if ($("#new_stock").children().length == 0){
    $("#new_stock").append("<span id='prompt' style='color:red;'>暂时没有关联的股票！</span>")
  }
  $("#stocks_search_ids").val(new_ids);
}
if ($("#new_stock").children().length == 0){
  $("#new_stock").append("<span id='prompt' style='color:red;'>暂时没有关联的股票！</span>")
}

function get_checkout_ids(){
  var ids = [];
  var bottoms = $('.bottom_tree')
  for(var i=0;i<bottoms.length;i++){  
    if(bottoms[i].checked){
      ids.push(bottoms[i].value)
      $("#check_"+i).remove();
    }
  }
  return ids
}

function initDescriptionEditor(textarea_id){
  KindEditor.ready(function(K) {
    editor = K.create('textarea[id="'+textarea_id+'"]', {
      resizeType : 0,
      // urlType: 'absolute',
      emoticonsPath: '/javascripts/kindeditor/plugins/emoticons/images/',
      uploadJson: '/kindeditor/upload', 
      allowPreviewEmoticons : false,
      allowImageUpload : true,
      allowImageRemote : false,
      // 加粗，下划线，斜体】【引用，有序列表，无序列表】【图片】
      items : ['bold', 'underline', 'italic', '|', 
                'insertorderedlist', 'insertunorderedlist', 'blockquote', '|', 
               'image', 'link', 'unlink', 'clearhtml', 'quickformat'],//, 'imagealigntop', 'imagealignleft', 'imagealignright'
      // themeType : 'simple',
      basePath: '/javascripts/kindeditor/',
      cssPath :[ '/javascripts/kindeditor/plugins/bockquote/bockquote.css'],
      width: '700px',
      height: '370px',
      pasteType: 1
    })
  })
}


function publishToFeed(params){
  $.post("/admin/feeds", params, function(response){
    if (response.status == true){
      alert("发送成功！");
    }
  })
}