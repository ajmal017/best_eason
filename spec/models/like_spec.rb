require "spec_helper"

describe Like do
  describe "validates" do
    it "is valid with user_id and likeable" do
      expect(build(:comment_like)).to be_valid
    end

    it "is not valid without user_id" do
      expect(build(:comment_like, :user_id => nil)).to have(1).errors_on(:user_id)
    end

    it "is not valid without likeable" do
      expect(build(:like)).to have(1).errors_on(:likeable_type)
      expect(build(:like)).to have(1).errors_on(:likeable_id)
    end

    it "can not create more with duplicate user_id and likeable" do
      like = create(:comment_like)
      expect(build(:comment_like, :likeable => like.likeable, :user_id => like.user_id)).not_to be_valid
    end
  end

  describe "callbacks" do
    context "when likeable_type is Comment" do
      it "send one notification" do
        expect{create(:comment_like)}.to change(Notification::Like, :count).by(1)
      end
    end
  end
end