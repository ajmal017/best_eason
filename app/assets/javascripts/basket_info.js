$(function(){
  // iframe 不刷新提交文件
  $("#real_avatar").change(function(){
    var currentForm = $(this).parents("form");
    if($("iframe[name='curform']").length > 0){
      var thisIframe = $("iframe[name='curform']");
    }else{
      var thisIframe = $("<iframe style='opacity:0;_filter:alpha(opacity=0)'></iframe>").attr("name",currentForm.attr("target"));
    }
    $(currentForm).after(thisIframe);
    $(currentForm).submit();
    $("#real_avatar").val("")
    showFloat();
  });
})

//form submit验证
function checkNewBasketThreeStep(){
  $("#btn_submit").attr("disabled", "disabled");
  $(".error_prompt span").remove();
  $(".richEditor").siblings(".notes_error").remove();
  $(".title_error").removeClass("error");
  var title = $.trim($("#basket_title").val());
  if (title == ""){
    $(".title_error").addClass("error");
    return false;
  }
}

//当在第二步点击上一步时，改变form的action、去掉onsubmit，然后提交到form数据到新的action
function previousStepAction(btn_obj, basket_id){
  var update_url = "/baskets/" + basket_id + "/update_attrs?step=3";
  var form = $(btn_obj).closest("form");
  $(form).attr("action", update_url);
  // (form).removeAttr("onsubmit");
  editor.sync();
  $(form).submit();
}

var editor;
function initDescriptionEditor(){
  KindEditor.ready(function(K) {
    editor = K.create('textarea[id="basket_description"]', {
      resizeType : 0,
      // urlType: 'absolute',
      emoticonsPath: '/javascripts/kindeditor/plugins/emoticons/images/',
      uploadJson: '/kindeditor/upload', 
      allowPreviewEmoticons : false,
      allowImageUpload : true,
      allowImageRemote : false,
      // 加粗，下划线，斜体】【引用，有序列表，无序列表】【图片】
      items : ['bold', 'underline', 'italic', '|', 
                'insertorderedlist', 'insertunorderedlist', 'bockquote', '|', 
               'image'],//, 'imagealigntop', 'imagealignleft', 'imagealignright'
      themeType : 'simple',
      basePath: '/javascripts/kindeditor/',
      cssPath :[ '/javascripts/kindeditor/plugins/bockquote/bockquote.css'],
      width: '598px',
      height: '370px',
      pasteType: 1
    })
  })
}


function showFloat(){
  CaishuoDialog.open({
    theme:"custom",
    title:'剪裁图片<i class="close-window" onclick="CaishuoDialog.close()"></i>',
    content: $('#FloatWindow'),
    reset: function(){
      $("#FloatWindow .footer input").val('确定').attr('disabled', false);
    },
    callback: function(){
      $("#FloatWindow form").submit();
      $("#FloatWindow .footer input").val('剪裁中...').attr('disabled', true);
      return true;
    },
    buttons:{confirm: $("#FloatWindow .footer input")}
  });

  $("#CaishuoDialog .footer input").hide();
}

function triggerRealAvatar(){
  $('#real_avatar').trigger('click');
  var loading_html = "<div class='barloading' style='min-height:200px;clear:both;'>图片上传中</div>";
  $("#FloatWindow .textbody").html(loading_html);
}

function cropPicAction(){
  $("#FloatWindow input[type=submit]").attr("disabled", "disabled").val("裁剪中...");
  return true;
}


// 设置裁剪坐标
var updateBasketCoordinate = function(c){
  if (parseInt(c.w) > 0){
    $('#basket_crop_x').val(c.x);
    $('#basket_crop_y').val(c.y);
    $('#basket_crop_w').val(c.w);
    $('#basket_crop_h').val(c.h);
  }
}

// @Jcrop 初始化
var BasketJcropInit = function(){
  var jcrop_api, boundx, boundy;
  var y_div_x = 0.8;

  $('#cropbox').Jcrop({
    onChange: updateBasketCoordinate,
    onSelect: updateBasketCoordinate,
    aspectRatio: 1.25
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

