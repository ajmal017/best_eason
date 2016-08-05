require "spec_helper"

describe Comment do
  describe "validates" do
    it "is valid with user_id and content, commentable" do
      expect(build(:comment_basket)).to be_valid
    end

    it "is not valid without content" do
      expect(build(:comment_basket, content: nil)).not_to be_valid
    end

    it "is not valid without user_id" do
      expect(build(:comment_basket, user_id: nil)).not_to be_valid
    end

    it "is not valid without commentable" do
      expect(build(:comment_basket, commentable: nil)).not_to be_valid
    end
  end

  describe "callbacks" do
    
  end
end