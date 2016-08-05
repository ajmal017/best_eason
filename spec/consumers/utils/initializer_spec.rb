require 'spec_helper'

class FooBar
  include CaishuoMQ::Consumer::Initializer
end

describe "Initializer" do
  context "snaking hash keys" do
    let(:foobar) { FooBar.new("real_filled" => 10, "real_shares" => 20) }
    
    subject { foobar }
    
    it_behaves_like :respond_and_values
  end
  
  context "camelized hash keys" do
    let(:foobar) { FooBar.new("realFilled" => 10, "realShares" => 20) }
    
    subject { foobar }
    
    it_behaves_like :respond_and_values
  end
  
  context "symbolized hash keys" do
    let(:foobar) { FooBar.new(real_filled: 10, real_shares: 20) }
    
    subject { foobar }
    
    it_behaves_like :respond_and_values
  end
end