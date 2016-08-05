shared_examples :user_not_exists do
  context 'binding user not exists' do
    it { lambda { subject }.should raise_error(ActiveRecord::RecordNotFound) }
  end
  
  context 'user not exists' do
    before :each do
      create(:user_binding, broker_user_id: "DU186928", user: nil)
    end
    
    it { lambda { subject }.should raise_error(BindingUserError)}
  end
end