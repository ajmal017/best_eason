var page = require('webpage').create(),
    system = require('system');
var url = system.args[1],
    path = system.args[2];
page.settings.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:33.0) Gecko/20100101 Firefox/33.0";
page.viewportSize = { width: 650, height: 200 };
page.open(url, function(status) {
  if (status === 'fail') {
    console.log('Request fail: '+ url);
  }else{
    page.render(path, {format: 'png', quality: '100'});
  }
  phantom.exit();
});
