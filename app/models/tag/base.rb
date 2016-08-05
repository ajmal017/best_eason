class Tag::Base < ActiveRecord::Base
  self.table_name = "tags"

  STATES = {"normal" => 0, "delete" => 1}

  validates :name, presence: true, uniqueness: {scope: [:type, :user_id], message: "名称重复"}

  has_many :taggings, dependent: :destroy, foreign_key: :tag_id

  scope :normal, -> { where(state: STATES["normal"]) }
  
  scope :without, ->(id) { where.not(id: id) if id.present? }

  def delete_by_state
    self.update(state: STATES["delete"])
  end
  
end