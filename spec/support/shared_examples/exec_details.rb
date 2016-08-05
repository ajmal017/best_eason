shared_examples :type_and_ele_type do
  it { should be_kind_of(Array) }
  
  it { should have_all_detail_elements }
end

shared_examples :hash_with_array_values do
  it { should be_kind_of(Hash) }

  it { should have_key(:api) }

  it { should have_key(:tws) }

  it { should have_all_array_values }
end

shared_examples :create_all_positions do
  it 'create two positions' do
    expect { subject }.to change(Position, :count).by(2)
  end
end

shared_examples :create_one_position do
  it 'create one position' do
    expect { subject }.to change(Position, :count).by(1)
  end
end

shared_examples :udpate_one_position do |current_status|
  it "does not update shares of position whose order_detail status is :#{current_status}" do
    expect { subject }.to_not change { @pos1.reload.shares }
  end

  it 'update shares of position whose order_detail status is :ready' do
    expect { subject }.to change { @pos2.reload.shares }.from(3).to(1000)
  end
end

shared_examples :update_all_posiitons do
  it 'update shares of all the positions' do
    expect { subject }.to change { [@pos1.reload.shares.to_i, @pos2.reload.shares.to_i] }.from([2,3]).to([-996,1000])
  end
end

shared_examples :public_behavior_bt_filled_and_cancelled do |current_status|
  it "does not update real_shares of order_detail whose status is :#{current_status}" do
    expect { subject }.to_not change { @od1.reload.real_shares }
  end
  
  it 'update real_shares of order_detail whose status is :ready' do
    expect { subject }.to change { @od2.reload.real_shares }.from(3).to(1000)
  end
  
  it "does not update real_cost of the order_detail whose status is :#{current_status}"do
    expect { subject }.to_not change { @od1.reload.real_cost }
  end
  
  it 'update real_cost of the order_detail whose status is :ready' do
    expect { subject }.to change { @od2.reload.real_cost }.from(30).to(1000*15.52)
  end
  
  it 'add real_cost of order corresponding to the order_detail real_cost whose status is :ready' do
    expect { subject }.to change { @order.reload.real_cost }.by(1000*15.52)
  end
end


shared_examples :public_behavior_bt_ready_and_submitted do |current_status|
  it 'update real_shares of all the order_details' do
    expect { subject }.to change { [@od1.reload.real_shares, @od2.reload.real_shares] }.from([2,3]).to([1000,1000])
  end
  
  it 'update real_cost of all the order_details' do
    expect { subject }.to change { [@od1.reload.real_cost, @od2.reload.real_cost] }.from([nil,30]).to([1000*15.54, 1000*15.52])
  end
  
  it 'update real_cost of the order' do
    expect { subject }.to change { @order.reload.real_cost }.from(2).to(2 + 1000*15.54 + 1000*15.52)
  end
  
  it "transition the status of all the order_details from :#{current_status} to :filled" do
    expect { subject }.to change { [@od1.reload.status, @od2.reload.status] }.from([current_status.to_s,current_status.to_s]).to(["filled", "filled"])
  end
end