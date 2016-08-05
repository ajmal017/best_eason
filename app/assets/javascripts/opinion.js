var Opinion = {
  opinionable_type: null,
  opinionable_id: null,

  render_callback: function(datas){
    var bullish_percent = datas.bullish_percent, bearish_percent = datas.bearish_percent;
    $("#opinions_chart .bullish").css("height", bullish_percent+"%").find("em").text(bullish_percent+"%看涨");
    $("#opinions_chart .bearish").css("height", bearish_percent+"%").find("em").text(bearish_percent+"%看跌");
    if (datas.logined){
      $("#opinions_btn button").removeClass('active');
      if (datas.up == true){
        $("#opinions_btn .handown").addClass("active");
      }else if(datas.down == true){
        $("#opinions_btn .handup").addClass("active");
      }
    }
  },

  init: function(options, render_callback){
    this.opinionable_type = options.opinionable_type;
    this.opinionable_id = options.opinionable_id;
    if (render_callback != undefined){
      this.render_callback = render_callback;
    }

    this.renderOpinions();

    $("#opinions_btn button").click(function(){
      $(this).addClass('active').siblings().removeClass('active');
      var opinion = $(this).hasClass('handup') ? 'down' : 'up';//前端class呈现反了
      Opinion.setOpinion(opinion);
    })
  },

  renderOpinions: function(render_callback){
    $.get("/ajax/opinions/datas?ts="+(new Date()).getTime(), {opinionable_type: Opinion.opinionable_type, opinionable_id: Opinion.opinionable_id}, function(response){
      Opinion.render_callback(response);
    })
  },

  setOpinion: function(opinion){
    $.post("/ajax/opinions", {opinion: opinion, opinionable_type: Opinion.opinionable_type, opinionable_id: Opinion.opinionable_id}, function(response){
      if (response.bullish_percent != undefined){
        Opinion.render_callback(response);
      }
    })
  }
}