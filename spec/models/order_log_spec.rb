require 'spec_helper'

describe OrderLog do
  describe 'validates' do
    it { should validate_presence_of(:ib_order_id) }
  end
end
