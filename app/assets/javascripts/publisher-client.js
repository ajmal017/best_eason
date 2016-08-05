//= require lib/sockjs-0.3.4.min
//= require lib/stomp.min

var Publisher = {
  config: gon.publisher,
  client: null,
  events: null,
  rules: {
    stock_index: {
      event: 'stock_indexes.update',
      hook: 'stockIndexHook'
    },
    order_trade: {
      event: gon.current_user_id + '.orders.trade',
      hook: 'orderTradeHook',
      private: true
    },
    order_error: {
      event: gon.current_user_id + '.orders.error',
      hook: 'orderErrorHook',
      private: true
    },
    order_finish: {
      event: gon.current_user_id + '.orders.finish',
      hook: 'orderFinishHook',
      private: true
    },
    stock_minute_price: {
      event: "stocks.minute_price",
      hook: 'stockMinutePrice'
    },
    stock_realtime_infos: {
      event: "stocks.realtime." + gon.stock_id,
      hook: 'stockRealtimePriceUpdateHook'
    }
  },
  // init method
  init: function(){
    this.connect();
  },
  configure: function(){
    this.events = this.config.events;
  },
  connect: function(){
    this.configure();
    var _ws = new SockJS(this.config.host);
    var _client = Stomp.over(_ws);
    if(this.config.debug == false){
      _client.debug = null;
    }
    _client.heartbeat.outgoing = 0;
    _client.heartbeat.incoming = 0;
    _client.connect(this.config.connect, this.onConnect, this.onError);
    this.client = _client;
  },
  disconnect: function(){
    this.client.disconnect();
  },
  onError: function(){
    console.log('error');
  },
  onConnect: function(x){
    Publisher.subscribeEvents();
  },
  subscribeEvents: function(){
    this.events.forEach(function(e){
      var _rules = Publisher.rules[e];
      if(_rules != null){
        Publisher.client.subscribe('/exchange/events/'+_rules.event, Publisher.hooks[_rules.hook], {id: 'sub_'+e});
      }
    });
  },
  unSubscribe: function(event){
    Publisher.client.unsubscribe('sub_'+event);
  },
  transformBody: function(data){
    if(typeof(data) != 'object' ){
      data = $.parseJSON(data);
      return this.transformBody(data);
    }
    return data;
  },
  // all hooks is below:
  hooks:{
    stockIndexHook: function(data) {
      MarketIndex.updateRtQuote(Publisher.transformBody(data.body));
    },
    orderTradeHook: function(data){
      OrderList.render(Publisher.transformBody(data.body))
    },
    orderErrorHook: function(data){
      OrderList.error(Publisher.transformBody(data.body))
    },
    orderFinishHook: function(data){
      OrderList.finish(Publisher.transformBody(data.body))
    },
    stockMinutePrice: function(data){
      // StockMinutePrice.updateMinutesChart();
    },
    stockRealtimePriceUpdateHook: function(data){
      StockRealtime.update(Publisher.transformBody(data.body));
    }
  }
};


// Call Publisher.init(), just after jQuery Loaded;
$(function(){
  Publisher.init();
});