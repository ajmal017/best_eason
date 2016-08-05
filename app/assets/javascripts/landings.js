$(function(){
  
  // iPhone特殊处理
  if(navigator.userAgent.match(/iPhone/i)){
    $('.s-form input, .s-error-message, .s-e-mail, .s-please-look, .s-please-look img').width('500');
    $('.number-img1 img, .font2 img, .font2, .chart').width('500');
  }

  $(".share1").mouseover(function(){
    $(".share-wechat").show();
  })
  
  $(".share1").mouseout(function(){
    $(".share-wechat").hide();
  })

  $("#j_go_buttom").on('click', function(){
    $("body, html").animate({scrollTop: $(window).height()}, "slow");
  })

  $("#j_weibo_share").on('click', function(){
    Share.weibo('http://www.caishuo.com', '财说海外投资之门即将开启');
  })

  $('#j_facebook_share').on('click', function(){
    Share.facebook('http://www.caishuo.com', '财说海外投资之门即将开启');
  })

  $("#j_twitter_share").on('click', function(){
    Share.twitter('http://www.caishuo.com', '财说海外投资之门即将开启');
  })

  $("#landing_email").focus(function(){
    $('.error-message').css('visibility', 'hidden');
  })

})

var collideFinished = true;

$(window).scroll(function(){
  var winHeight = $(window).height();
  var scrollTop = $(window).scrollTop();
  if (_mobilePlatform == 'false' && collideFinished && $('#j_us_stock').offset().top < winHeight + scrollTop){
    collideFinished = false;
    $('#j_us_stock').animate({left: 0}, 400);
    $('#j_hk_stock').animate({left: 150}, 400, function(){
      $('.ellipsis').show('slow');
    });
  }
})

var caishuoFacebookUrl = function(){
  return 'https://www.facebook.com/pages/%E8%B4%A2%E8%AF%B4/259425167580930';
}

var caishuoTwitterUrl = function(){
  return 'https://twitter.com/caishuo123'; 
}

var caishuoWeiboUrl = function(){
  return 'http://weibo.com/touzhuti';
}
