shared_examples :not_precesss_message do
  subject { OrderStatus.new.work(other_message) }
  
  it 'does not update the status of order' do
    expect { subject }.to_not change { @order.status }
  end
  
  it 'ack drop to rabbit' do
    expect(subject).to eq "drop"
  end
end