require 'spec_helper'

describe AccountValue do
  describe 'db_column_and_index' do
    it { should have_db_index([:user_binding_id, :key, :currency]).unique(true) }
  end
end
