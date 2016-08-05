require 'spec_helper'

describe Basket do
  describe "create new basket" do
    before :each do
      @basket = create(:basket)
    end

    it "state is new" do
      expect(@basket.state).to eq Basket::STATE[:new]
    end

    it "user_id is presence" do
      expect(@basket.user_id.present?).to eq true
    end

    it "invalid user_id" do
      expect(@basket.update(user_id: nil)).to_not be_true
    end
  end

  describe "update_stocks" do
    context "success with valid weights when basket is new" do
      before :each do
        stock_1 = create(:stock)
        stock_2 = create(:stock)
        stock_3 = create(:stock)
        @basket_params = {:basket_stocks_attributes => {"0" => {weight:'0.321', stock_id:stock_1.id}, 
                                                       "1" => {weight:'0.226', stock_id:stock_2.id}, 
                                                       "2" => {weight:'0.453', stock_id:stock_3.id}}}
        @basket = create(:basket)
      end

      it "basket is valid" do
        @basket.update_stocks(@basket_params)
        expect(@basket.valid?).to eq true
      end

      it "added 3 basket_stocks" do
        @basket.update_stocks(@basket_params)
        expect(@basket.basket_stocks.count).to eq 3
      end
    end

    context "success with valid weights when basket had completed" do
      before :each do
        @basket = create(:basket_with_one_stock)
        @basket.basket_stocks.reload
        @basket.update_stocks_step_three({title: "test"})
        
        stock_1 = create(:stock)
        stock_2 = create(:stock)
        @basket_params = {:basket_stocks_attributes => {"0" => {weight:'0.321', stock_id:stock_1.id}, 
                              "1" => {weight:'0.226', stock_id:stock_2.id}, 
                              "2" => {weight:'0.453', stock_id:@basket.stocks.first.id}}}
      end

      it "basket is valid" do
        @basket.update_stocks(@basket_params)
        expect{ @basket.is_valid? }.to be_true
      end
    end

    context "failure with invalid weights" do
      before :each do
        stock_1 = create(:stock)
        stock_2 = create(:stock)
        basket_params = {:basket_stocks_attributes => {"0" => {weight:'0.321', stock_id:stock_1.id}, 
                                                       "1" => {weight:'0.226', stock_id:stock_2.id}}}
        @basket = create(:normal_basket)
        @basket.update_stocks(basket_params)
      end

      it "has one error" do
        expect(@basket).to have(1).errors_on(:stock_weight)
      end

      it "update failure" do
        expect(@basket.basket_stocks.count).to eq 0
      end
    end

    context "multi area stocks" do
      it "multi area stocks" do
        us_stock = create(:base_stock)
        hk_stock = create(:hk_stock)
        basket_params = {:basket_stocks_attributes => {"0" => {weight:'0.3', stock_id:us_stock.id}, 
                                                       "1" => {weight:'0.7', stock_id:hk_stock.id}}}
        @basket = create(:basket)
        expect(@basket.update_stocks(basket_params)).to eq false
      end
    end
  end

  describe "update stocks step three" do
  	context "update success" do
      before :each do
        @basket = create(:basket_with_stocks)
        @basket.reload # why can not get basket_stocks without reload?
      end

      it "has 5 basket_stock" do
        @basket.update_stocks_step_three({title: "test"})
        expect(@basket.basket_stocks.count).to eq 5
      end

      it "start_on is exist" do
        @basket.update_stocks_step_three({title: "test"})
        expect(@basket.start_on.present?).to eq true
      end

      it "create one basket_index" do
        @basket.update_stocks_step_three({title: "test"})
        expect(@basket.basket_indices.present?).to eq true
      end

      it "generate abbrev" do
        @basket.update_stocks_step_three({title: "test"})
        expect(@basket.abbrev.present?).to eq true
      end

      it "update modified_at" do
        @basket.update_stocks_step_three({title: "test"})
        expect(@basket.modified_at.present?).to eq true
      end

      it "weight changed at today" do
        @basket.update_stocks_step_three({title: "test"})
        expect { @basket.weight_changed?(Date.today) == true }.to be_true
      end

      it "create basket weight log" do
        expect {@basket.update_stocks_step_three({title: "test"})}.to change(BasketWeightLog, :count).by(5)
      end

      it "state is normal or say completed" do
        @basket.update_stocks_step_three({title: "test"})
        expect(@basket.completed?).to eq true
      end
    end

  end

end