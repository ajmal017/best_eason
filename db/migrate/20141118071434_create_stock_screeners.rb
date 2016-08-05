class CreateStockScreeners < ActiveRecord::Migration
  def change
    create_table :stock_screeners do |t|
      t.integer :base_stock_id, null: false
      t.string :symbol
      t.boolean :exchange_us, null: false, default: false, comment: '美股市场'
      t.float :score, null: false, default: 0.0, comment: '股票星级'
      t.boolean :exchange_hk, null: false, default: false, comment: '港股市场'
      t.boolean :sector_bm, null: false, default: false, comment: '基础材料'
      t.boolean :sector_c, null: false, default: false, comment: '综合型大企业'
      t.boolean :sector_cg, null: false, default: false, comment: '消费品'
      t.boolean :sector_f, null: false, default: false, comment: '金融'
      t.boolean :sector_h, null: false, default: false, comment: '医疗'
      t.boolean :sector_ig, null: false, default: false, comment: '工业'
      t.boolean :sector_s, null: false, default: false, comment: '服务业'
      t.boolean :sector_t, null: false, default: false, comment: '高科技'
      t.boolean :sector_u, null: false, default: false, comment: '公用事业'
      t.boolean :sector_o, null: false, default: false, comment: '其他'
      t.boolean :style_lp, null: false, default: false, comment: '价格低'
      t.boolean :style_hg, null: false, default: false, comment: '高增长'
      t.boolean :style_hq, null: false, default: false, comment: '高质量'
      t.boolean :opinion_l, null: false, default: false, comment: '华尔街看多'
      t.boolean :opinion_s, null: false, default: false, comment: '华尔街看空'
      t.boolean :trend_g10, null: false, default: false, comment: '当前价高于十日均线'
      t.boolean :trend_l10, null: false, default: false, comment: '当前价低于十日均线'
      t.boolean :trend_h52, null: false, default: false, comment: '当前价逼近52周最高'
      t.boolean :trend_l52, null: false, default: false, comment: '当前价逼近52周最低'
      t.boolean :consideration_sc, null: false, default: false, comment: '小市值（<十亿美金）'
      t.boolean :consideration_bc, null: false, default: false, comment: '大市值（>百亿美金）'
      t.boolean :consideration_tg, null: false, default: false, comment: '去年盈利且今年展望盈利'
      t.boolean :consideration_bg, null: false, default: false, comment: '盈利反转（去年亏损今年展望盈利）'
      t.boolean :consideration_gg, null: false, default: false, comment: '持续增长（营收及每股盈利展望高于去年）'
      t.boolean :consideration_hg, null: false, default: false, comment: '高增长（营收增长预期 > 16%）'
      t.boolean :consideration_div, null: false, default: false, comment: '有分红'
      t.boolean :consideration_dgc, null: false, default: false, comment: '现金及投资超过借贷的'

      t.boolean :country_usa, null: false, default: false, comment: '美国'
      t.boolean :country_can, null: false, default: false, comment: '加拿大'
      t.boolean :country_isr, null: false, default: false, comment: '以色列'
      t.boolean :country_chn, null: false, default: false, comment: '中国'
      t.boolean :country_others, null: false, default: false, comment: '其他'

      t.decimal :wst_2, :decimal, precision: 18, scale: 6, default: 0.0, comment: "华尔街目标价格，wst为比例"
      t.decimal :div_2, :decimal, precision: 18, scale: 6, default: 0.0, comment: "现金分红，div为比例"
    end

    add_index :stock_screeners, :base_stock_id, unique: true
  end
end
