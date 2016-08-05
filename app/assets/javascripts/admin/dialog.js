function init_dialog(v_title, v_width, v_height, settings){
  // var _require_ga = settings != null && settings.ga_category != null ;
  $("#dialog_ui").dialog({
      cache: false,
      // modal: true,
      resizable: false,
      title: v_title,
      width: v_width || 400,
      height: v_height || 300,
      zIndex: 9999
      // open: function(){
      //   if(_require_ga)
      //     ga_open_dialog(settings.ga_category);
      // },
      // close: function(){
      //   if(_require_ga)
      //     ga_close_dialog(settings.ga_category);
      // }
  });
}

// dialog by local
// open_dialog("这里是标题", "<b>Hello</b>", 310, 220)
// open_dialog("这里是标题", "<b>Hello</b>")   
function open_dialog(v_title, v_body, v_width, v_height) {
    $("#dialog_ui").html(v_body||'');
    init_dialog(v_title, v_width, v_height);
}


// dialog by remote
// settings 接受一个JSON对象作为扩展参数
// 参数如下：
// auto_focus 表单的第一个textarea是否自动获得焦点，默认为true
// 
// Demo:
// remote_dialog("/your/ajax/path", "这里是标题", 310, 220);    => GET /your/ajax/path
// remote_dialog("/your/ajax/path", "这里是标题", 310, 220, {key1: value1, key2: values});  => POST /your/ajax/path
// remote_dialog("/your/ajax/path", "这里是标题", 310, 220, {key1: value1, key2: values}, {auto_focus: false});
function remote_dialog(v_url, v_title, v_width, v_height, v_data, settings) {
    settings = $.extend({
        auto_focus: true
    }, settings);
    init_dialog(v_title, v_width, v_height, settings);
    $("#dialog_ui").html('正在加载...');
    if(v_data == null || (typeof(v_data) == "object" && v_data.get == true)) {
        t_data = null;
    } else {
        t_data = {
            data: v_data
        };
    }
    $("#dialog_ui").load(v_url, t_data, function(responseText, textStatus, XMLHttpRequest) {
        if (settings.auto_focus) {
            $("#dialog_ui textarea:first").focus();
        }
    });
}

