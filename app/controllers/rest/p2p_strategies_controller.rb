class Rest::P2pStrategiesController < Rest::BaseController
  def index
    @ps = P2pStrategy.all.group_by{|p|p.mentionable.try(:c_name)}.reduce({}){|n,(k,v)| n[k] = v.map(&:format_data); n}
    present @ps
  end

  # 获取策略在某日期区间内的浮动盈亏比例
  # POST
  # params [:p2p_strategies] = [{id: 1, sd: "20151112", ed: "20151115"}]
  # return [0.15, 0.24]
  def profit
    requires :p2p_strategies
    raise "p2p_strategies为空" unless params[:p2p_strategies].size > 0

    ids = params[:p2p_strategies].map{|n| n[:id].to_i }
    @ps = P2pStrategy.where(id: ids).inject({}){|i,j| i[j.id] = j;i }

    unfind_ids = ids.uniq - @ps.keys
    raise "没有找到id:#{unfind_ids}的数据" if unfind_ids.present?

    present params[:p2p_strategies].map{ |n| @ps[n[:id].to_i].profit(Date.parse(n[:sd]), Date.parse(n[:ed])) }
  end
end
