# baskets版本管理调整 201503
namespace :change_baskets_structure do
  desc "baskets相关数据迁移"
  task :init => :environment do
    return false
    
    Basket.where(id: [492, 787, 788]).each do |b|
      b.update(parent_id: nil, original_id: nil)
    end

    process_baskets_datas
  end

  def process_baskets_datas
    puts "step 1 ------------------------------"
    start_time = Time.now
    baskets = Basket.normal
    baskets.each do |basket|
      puts basket.id
      next if basket.draft?
      copy_current_normal_basket_to_history(basket)
    end
    puts "step1 over, 继续其它任务"

    process_comments_datas
    process_basket_counters
    process_topics_datas
    process_api_exec
    process_baskets_wrong_datas
    puts Time.now - start_time
    puts "all end!"
  end

  def copy_current_normal_basket_to_history(basket)
    necessary_attribute_names = basket.attribute_names - ["id", "type"]
    necessary_attributes = basket.attributes.slice(*necessary_attribute_names).merge(original_id: basket.id)

    ActiveRecord::Base.transaction do
      # copy一份到历史版本
      history_basket = Basket::History.new(necessary_attributes.merge(img: basket.img.larger))
      history_basket.save(validate: false)
      # copy basket_stocks
      basket_stock_attribute_names = ["stock_id", "weight", "notes", "adjusted_weight", "created_at", "updated_at", "ori_weight"]
      copyed_basket_stocks = basket.basket_stocks.map do |bs|
        attrs = bs.attributes.slice(*basket_stock_attribute_names).merge(basket_id: history_basket.id)
        BasketStock.new(attrs)
      end
      BasketStock.import(copyed_basket_stocks)
      # 记录最新history_id
      Basket.where("id=?", basket.id).update_all(latest_history_id: history_basket.id)
      # 更改历史记录，所有history的original_id都指向当前basket normal；更新custom original_id
      Basket::History.where("original_id = ? or id = ?", basket.original_id, basket.original_id)
                     .update_all(original_id: basket.id)
      Basket.where(type: ['Basket::Custom', 'Basket::CustomHistory'])
            .where(original_id: basket.original_id).update_all(original_id: basket.id)

      # 其他关联数据迁移
      process_other_basket_relations(basket, history_basket)
      
      # original_id设置成自己的id
      Basket.where("id=?", basket.id).update_all(original_id: basket.id, parent_id: history_basket.id)
    end
  end

  def process_other_basket_relations(basket, history_basket)
    process_basket_adjustment(basket, history_basket)
    process_basket_opinion(basket)
    process_orders_data(basket, history_basket)
    process_follows_datas(basket)
  end

  def process_basket_adjustment(basket, history_basket)
    BasketAdjustment.where(original_basket_id: basket.original_id).update_all(original_basket_id: basket.id)
    BasketAdjustment.where(next_basket_id: basket.id).update_all(next_basket_id: history_basket.id)
    # BasketAdjustLog, BasketStockSnapshot 不用迁移
  end

  def process_basket_index_and_weight_logs()
    # history 版本的indexs及basket_weight_logs可以删除
    # 当前normal的不用处理
    # todo
  end

  def process_basket_opinion(basket)
    BasketOpinion.where(original_basket_id: basket.original_id).update_all(original_basket_id: basket.id)
  end

  def process_orders_data(basket, history_basket)
    Order.baskets.where(basket_id: basket.id).update_all(basket_id: history_basket.id)
    Order.baskets.where(instance_id: basket.original_id.to_s).update_all(instance_id: basket.id.to_s)

    OrderDetail.where(basket_id: basket.id).update_all(basket_id: history_basket.id)
    OrderDetail.where(instance_id: basket.original_id.to_s).update_all(instance_id: basket.id.to_s)

    # ExecDetail basket_id格式为 instance_id:basket_id，且该表为历史表，暂时只处理instance_id，basket_id数据可后续处理
    # ExecDetail.where(basket_id: basket.id.to_s).update_all(basket_id: history_basket.id.to_s)
    ExecDetail.where(instance_id: basket.original_id.to_s).update_all(instance_id: basket.id.to_s)

    Position.where(basket_id: basket.id).update_all(basket_id: history_basket.id)
    Position.where(instance_id: basket.original_id.to_s).update_all(instance_id: basket.id.to_s)

    PositionArchive.where(basket_id: basket.id).update_all(basket_id: history_basket.id)
    PositionArchive.where(instance_id: basket.original_id.to_s).update_all(instance_id: basket.id.to_s)

    OrderStockShare.where(instance_id: basket.original_id.to_s).update_all(instance_id: basket.id.to_s)
  end

  def process_comments_datas
    # 在basket相关批量处理完，单独执行history basket =》 normal basket
    Comment.where(commentable_type: "Basket").find_each do |comment|
      next unless comment.commentable
      comment.update(commentable_id: comment.commentable.original_id)
    end
    puts "comments end"
  end

  def process_follows_datas(basket)
    Follow.for_basket.where(followable_id: basket.original_id).update_all(followable_id: basket.id)
  end

  def process_topics_datas
    # topic_baskets 重跑
    TopicBasketWorker.perform
    # topic basket_ids all to normal version
    Topic.find_each do |topic|
      new_ids = topic.selected_topic_baskets.map(&:id).join(",")
      topic.update(basket_ids: new_ids)
    end
    puts "topics end"
  end

  def process_notifications_datas()
    # basket迁移完成后批量处理notification comment、mention
    # 不用处理
  end

  def process_articles_datas()
    # related_baskets不用处理，history会自动跳转到normal，也可后台重新设置
  end

  def process_recommend_basket()
    # 不用处理，现在取的basket_id可正常使用
  end

  def process_basket_counters
    # basket normal comments_count / follows_count
    Basket.normal.find_each do |basket|
      basket.update(
        follows_count: basket.follows.count, 
        comments_count: basket.comments.count
        )
    end
    puts "basket counters end"
  end

  def process_api_exec
    ApiExec.where.not(instance_id: "others").find_each do |exec|
      exec.update(basket_id: "#{exec.instance_id}:#{exec.order_id}")
    end
  end

  # 
  def process_baskets_wrong_datas
    Basket.normal.where("parent_id = id").each do |b|
      b.update(parent_id: b.latest_history_id)
      Basket::History.where(parent_id: b.id).update_all(parent_id: nil)
    end

    # 上线不用执行
    # Basket.normal.each do |b|
    #   b.update(parent_id: b.latest_history_id)
    # end

    Basket::History.all.where("parent_id is not null").each do |b|
      next unless b.parent.nil?
      b.update(parent_id: nil)
    end

    bids = Basket.normal.map(&:id)
    Basket::History.where(parent_id: bids).each do |b|
      b.update(parent_id: nil)
    end

    puts "批量处理部分错误数据 end"
  end
end