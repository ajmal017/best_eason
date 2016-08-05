class AdminTemplate

  CATEGORIES = {
    global: {name: "自动生成器", template: :global},
    title: {name: "页面标题", template: :title},
    menu: {name: "子导航", template: :title},
    search: {name: "搜索框", template: :title},
    grid: {name: "数据表格", template: :grid},
    form: {name: "表单", template: :form},
    show: {name: "show页面", template: :show},
    local_dialog: {name: "本地弹窗", template: :dialog},
    remote_dialog: {name: "AJAX弹窗", template: :dialog},
    upload: {name: "上传文件", template: :upload},
    batch_delete: {name: "批量删除", template: :batch_delete},
    auto_search: {name: "自动检索", template: :auto_search}
  }


  CODES = {
    header: %Q{
<h1 class="title">
 <span class="title_left"><%=@page_title%></span>
</h1>},
    title: %Q{
<!--页面标题-->
<h1 class="title">
 <span class="title_left"><%=@page_title%></span>
 <span class="title_right"><%=link_to "右侧链接", "#"%></span>
</h1>},
    menu: %Q{
<!--子导航-->
<div class="box">
  <a href="#" class="current">全部</a>
  <% 5.times do |i| %>
    <a href="#">分类<%=i+1%></a>
  <% end -%>
</div>},
    search: %Q{
<!--搜索框-->
<div class="box">
  <%= search_form_for search, url: admin_articles_path do |f| %>
    <%= f.text_field :title_cont, :placeholder => "标题" %>
    <%= f.select :synchronized_eq, Article::SYNCHRONIZED.map{|key, value| [key, value]}, {prompt: "已同步？"} %>
    <%= f.select :categories_code_eq, Category::ARTICLES.map{|key, value| [value, key]}, {prompt: "类别"} %>
    <%= f.submit "搜索"%>
  <% end %>
</div>},
    page_info: %Q{
<%= page_info(@base_stocks) %>},
    grid: %Q{
<table class="grid">
  <thead>
    <tr>
      <%= content_tag :th, sort_link(q, :symbol, '股票代码') %>
      <%= content_tag :th, sort_link(q, :ib_symbol, 'IB股票代码') %>
      <%= content_tag :th, sort_link(q, :name, '名称') %>
      <th>交易所</th>
      <th>操作</th>
    </tr>
  </thead>
  <tbody>
    <% @base_stocks.each_with_index do |bs, index| %>
      <tr>
        <td><%= link_to(bs.symbol, stock_path(bs), target: "_blank",title: "查看详情") %></td>
        <td><%= bs.ib_symbol %></td>
        <td class="align_left"><%= bs.com_name %></td>
        <td><%= bs.exchange %></td>
        <td class="action">
          <%= render "commands", :bs => bs %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
<%= will_paginate @base_stocks %>},
    blank_grid: %Q{
<table class="grid">
  <thead>
    <tr>
      <%= content_tag :th, sort_link(q, :symbol, '股票代码') %>
      <%= content_tag :th, sort_link(q, :ib_symbol, 'IB股票代码') %>
      <%= content_tag :th, sort_link(q, :name, '名称') %>
      <th>交易所</th>
      <th>操作</th>
    </tr>
  </thead>
  <tbody>
    <%= blank_table(5) if @base_stocks.blank? %>
  </tbody>
</table>},
    form: %Q{
<%= form_for @staffer  do |f|%>
  <table class="grid_form">
    <tbody>
      <tr>
        <td class="field"><b>*</b>电子邮箱:</td>
        <td>
          <%= f.text_field :email, :size=>30 %>
        </td>
      </tr>
      <tr>
        <td class="field"><b>*</b>密码:</td>
        <td>
          <%= f.password_field :password, :size=>20 %>
        </td>
      </tr>
      <tr>
        <td class="field"><b>*</b>是否为超级管理员:</td>
        <td>
          <%= f.check_box :admin %>
        </td>
      </tr>
      <tr>
        <td class="field"><b>*</b>角色名称:</td>
        <td>
          <%= f.select :role_id, Admin::Role.all.map{|x| [x.name, x.id]}, prompt: '请选择'%>
        </td>
      </tr>
      <tr>
        <td class="field"></td>
        <td>
          <%= f.submit %>
        </td>
      </tr>
    </tbody>
  </table>
<% end -%>},
    show: %Q{
<table class="grid_form">
  <tbody>
    <tr>
      <td class="field"><b>*</b>手机号:</td>
      <td><%=@lead.mobile%></td>
    </tr>
    <tr>
      <td class="field">性别</td>
      <td><%=@lead.gender%></td>
    </tr>
    <tr>
      <td class="field">公司: </td>
      <td><%=@lead.company%></td>
    </tr>
  </tbody>
</table>},
    local_dialog: %Q{
// 本地弹窗:
open_dialog("这里是标题", "<b>Hello</b>", 310, 220)
open_dialog("这里是标题", "<b>Hello</b>")},
    remote_dialog: %Q{
// AJAX弹窗:
remote_dialog("/your/ajax/path", "这里是标题", 310, 220);    => GET /your/ajax/path
remote_dialog("/your/ajax/path", "这里是标题", 310, 220, {key1: value1, key2: values});  => POST /your/ajax/path
remote_dialog("/your/ajax/path", "这里是标题", 310, 220, {key1: value1, key2: values}, {auto_focus: false});
    },
    upload: %Q{
      <scirpt type="text/javascript">
      $("#upload_common_file_btn").uploader({url_field_id: "upload_pic", a_link_id: "upload_img_a_link", image_show_id: "upload_img"});
      </script>
    },
    batch_delete: %Q{
      $('.top_tree').click(function(){......});
      $('.bottom_tree').click(function(){......});
      function get_checkout_ids(){......return ids}
    },
    auto_search_stock: %Q{
      $("#stock_search").autocomplete({
        //得到满足条件的stock
        source: function( request, response ) {$.ajax({url: "/ajax/stocks/search"});},
        //追加一个stock
        select: function( event, ui ) {$("#new_stock").append("......")}
        //显示满足条件的stocks
      }).autocomplete( "instance" )._renderItem = function( ul, item ) {};
    },
    auto_search_user: %Q{
      $(".select_user").select2({
        placeholder: "用户名",
        ajax: {url: "/ajax/global/search_user"},
        templateResult: formatUser, //显示查询结果
        templateSelection: formatUserSelection, //显示选中的对象
        escapeMarkup: function (markup) { return markup; }
      });
      function formatUser (user) {......} //返回正在加载的数据
      function formatUserSelection (user) {......} //在搜索框中显示选中的用户
    }
  }

end