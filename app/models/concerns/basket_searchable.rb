# 组合es搜索配置
module BasketSearchable
  extend ActiveSupport::Concern

  included do
    alias_attribute :class_type, :type

    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'false' do
        indexes :id, type: :integer
        indexes :title, type: :string, index: :analyzed
        indexes :abbrev, type: :string, index: :analyzed
        indexes :cleaned_description, type: :string, index: :analyzed
        indexes :author_id, type: :integer
        indexes :state, type: :integer
        indexes :start_on, type: :date
        indexes :modified_at, type: :date
        indexes :adjustment_at, type: :date
        indexes :one_day_return, type: :double
        indexes :one_month_return, type: :double
        indexes :one_year_return, type: :double
        indexes :total_return, type: :double
        indexes :bullish_percent, type: :double
        indexes :hot_score, type: :double
        indexes :visible, type: :boolean
        indexes :contest, type: :integer
        indexes :class_type, type: :string, index: :not_analyzed
        indexes :market, type: :string, index: :not_analyzed
        indexes :tag_ids, index: :not_analyzed
      end
    end
  end

  def as_indexed_json(options = {})
    as_json(
      only: [:id, :title, :author_id, :abbrev, :state, :start_on, :one_day_return,
             :one_month_return, :one_year_return, :bullish_percent, :hot_score, :modified_at,
             :visible, :total_return, :market, :contest],
      methods: [:adjustment_at, :tag_ids, :class_type, :cleaned_description]
      # include: {
      #   author: { only: [:username, :id] },
      #   tags: { only: [:id, :name] }
      # }
    )
  end

  # def img_large_url
  #   img_url(:large)
  # end

  def adjustment_at
    latest_adjustment.try(:created_at) || start_on
  end

  def cleaned_description
    Caishuo::Utils::Helper.helper.strip_tags(description)
  end

  def can_index_to_es?
    normal?
  end
end
