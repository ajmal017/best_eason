#encoding=utf-8
require 'spec_helper'

feature 'reconcile request lists management' do
  background  do
    admin = create(:admin_staffer)
    admin_sign_in(admin)
  end
  
  background do
    create(:reconcile_request_list)
  end
  
  scenario 'check reconcile request lists' do
    visit nimda_path
    expect(page).to have_content '调平请求列表'
    
    click_link '调平请求列表'
    within 'legend' do
      expect(page).to have_content '调平请求列表'
    end
    
    expect(page).to have_field('broker账号')
    expect(page).to have_field('symbol')
    expect(page).to have_button('搜索')
    expect(page).to have_table('reconcile_requests')
    expect(page).to have_content '调平等级'
  end
end