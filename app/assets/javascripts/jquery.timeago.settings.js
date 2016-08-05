(function() {
  var localized = {
    prefixAgo: null,
    prefixFromNow: null,
    suffixAgo: "前",
    suffixFromNow: "",
    seconds: "刚刚",
    minute: "1 分钟",
    minutes: "%d 分钟",
    hour: "1 小时",
    hours: "%d 小时",
    day: "1 天",
    days: "%d 天",
    month: "1 月",
    months: "%d 月",
    year: "1 年",
    years: "%d 年",
    numbers: [],
    formatter: function(prefix, words, suffix) { return [prefix, words, suffix].join(""); }
  }

  if (localized) {
    jQuery.timeago.settings.strings = localized;
  }

})();
