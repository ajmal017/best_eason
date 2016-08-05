shared_examples :respond_and_values do
  it { should respond_to :real_shares }
  
  it { should respond_to :real_filled }
  
  it "returns value of real_filled" do
    expect(foobar.real_filled).to eq 10
  end
  
  it "returns value of real_shares" do
    expect(foobar.real_shares).to eq 20
  end
end