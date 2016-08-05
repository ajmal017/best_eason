require "spec_helper"

describe Follow do
  describe "validates" do
    it "is valid with user_id and followable" do
      expect(build(:basket_follow)).to be_valid
    end

    it "is not valid without followable" do
      expect(build(:follow)).to have(1).errors_on(:followable_type)
      expect(build(:follow)).to have(1).errors_on(:followable_id)
    end

    it "is not valid without user_id" do
      expect(build(:follow, :user_id => nil)).to have(1).errors_on(:user_id)
    end

    it "can not create more with duplicate user_id and followable" do
      follow = create(:basket_follow)
      expect(build(:basket_follow, :followable => follow.followable, :user_id => follow.user_id)).not_to be_valid
    end
  end

  describe "callbacks" do
    context "when followable_type is Basket" do
      it "send one notification" do
        expect{create(:basket_follow)}.to change(Notification::Follow, :count).by(1)
      end
    end
  end

  describe "class methods" do
    context "followed_baskets_by_user" do
      it "has two followed baskets" do
        follow = create(:basket_follow)
        create(:basket_follow, :user_id => follow.user_id)
        expect(Follow.followed_baskets_by_user(follow.user_id).size).to eq 2
      end
    end
  end
end