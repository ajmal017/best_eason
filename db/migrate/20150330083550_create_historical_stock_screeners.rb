class CreateHistoricalStockScreeners < ActiveRecord::Migration
  def change
    create_table :historical_stock_screeners do |t|
      t.integer "base_stock_id",       limit: 4,                                            null: false
      t.string  "symbol",              limit: 255
      t.boolean "exchange_us",         limit: 1,                            default: false, null: false, comment: "美股市场"
      t.float   "score",               limit: 24,                           default: 0.0,   null: false, comment: "股票星级"
      t.boolean "exchange_hk",         limit: 1,                            default: false, null: false, comment: "港股市场"
      t.boolean "sector_bm",           limit: 1,                            default: false, null: false, comment: "基础材料"
      t.boolean "sector_c",            limit: 1,                            default: false, null: false, comment: "综合型大企业"
      t.boolean "sector_cg",           limit: 1,                            default: false, null: false, comment: "消费品"
      t.boolean "sector_f",            limit: 1,                            default: false, null: false, comment: "金融"
      t.boolean "sector_h",            limit: 1,                            default: false, null: false, comment: "医疗"
      t.boolean "sector_ig",           limit: 1,                            default: false, null: false, comment: "工业"
      t.boolean "sector_s",            limit: 1,                            default: false, null: false, comment: "服务业"
      t.boolean "sector_t",            limit: 1,                            default: false, null: false, comment: "高科技"
      t.boolean "sector_u",            limit: 1,                            default: false, null: false, comment: "公用事业"
      t.boolean "sector_o",            limit: 1,                            default: false, null: false, comment: "其他"
      t.boolean "style_lp",            limit: 1,                            default: false, null: false, comment: "价格低"
      t.boolean "style_hg",            limit: 1,                            default: false, null: false, comment: "高增长"
      t.boolean "style_hq",            limit: 1,                            default: false, null: false, comment: "高质量"
      t.boolean "opinion_l",           limit: 1,                            default: false, null: false, comment: "华尔街看多"
      t.boolean "opinion_s",           limit: 1,                            default: false, null: false, comment: "华尔街看空"
      t.boolean "trend_g10",           limit: 1,                            default: false, null: false, comment: "当前价高于十日均线"
      t.boolean "trend_l10",           limit: 1,                            default: false, null: false, comment: "当前价低于十日均线"
      t.boolean "trend_h52",           limit: 1,                            default: false, null: false, comment: "当前价逼近52周最高"
      t.boolean "trend_l52",           limit: 1,                            default: false, null: false, comment: "当前价逼近52周最低"
      t.boolean "consideration_sc",    limit: 1,                            default: false, null: false, comment: "小市值（<十亿美金）"
      t.boolean "consideration_bc",    limit: 1,                            default: false, null: false, comment: "大市值（>百亿美金）"
      t.boolean "consideration_tg",    limit: 1,                            default: false, null: false, comment: "去年盈利且今年展望盈利"
      t.boolean "consideration_bg",    limit: 1,                            default: false, null: false, comment: "盈利反转（去年亏损今年展望盈利）"
      t.boolean "consideration_gg",    limit: 1,                            default: false, null: false, comment: "持续增长（营收及每股盈利展望高于去年）"
      t.boolean "consideration_hg",    limit: 1,                            default: false, null: false, comment: "高增长（营收增长预期 > 16%）"
      t.boolean "consideration_div",   limit: 1,                            default: false, null: false, comment: "有分红"
      t.boolean "consideration_dgc",   limit: 1,                            default: false, null: false, comment: "现金及投资超过借贷的"
      t.decimal "pe",                              precision: 18, scale: 3, default: 0.0,                comment: "市盈率"
      t.decimal "pe_c",                            precision: 18, scale: 3, default: 0.0
      t.decimal "lpg",                             precision: 18, scale: 3, default: 0.0,                comment: "长期盈利增长"
      t.decimal "lpg_c",                           precision: 18, scale: 3, default: 0.0
      t.decimal "cf",                              precision: 18, scale: 3, default: 0.0,                comment: "现金流"
      t.decimal "cf_c",                            precision: 18, scale: 3, default: 0.0
      t.decimal "gm",                              precision: 18, scale: 3, default: 0.0,                comment: "毛利润率"
      t.decimal "gm_c",                            precision: 18, scale: 3, default: 0.0
      t.decimal "wst",                             precision: 18, scale: 3, default: 0.0,                comment: "华尔街目标价格"
      t.decimal "wst_c",                           precision: 18, scale: 3, default: 0.0
      t.decimal "div",                             precision: 18, scale: 3, default: 0.0,                comment: "现金分红"
      t.decimal "div_c",                           precision: 18, scale: 3, default: 0.0
      t.integer "c1",                  limit: 4
      t.integer "c2",                  limit: 4
      t.integer "c3",                  limit: 4
      t.integer "c4",                  limit: 4
      t.integer "c5",                  limit: 4
      t.integer "c6",                  limit: 4
      t.integer "c7",                  limit: 4
      t.integer "c8",                  limit: 4
      t.integer "c9",                  limit: 4
      t.integer "c10",                 limit: 4
      t.integer "c11",                 limit: 4
      t.integer "c12",                 limit: 4
      t.integer "c13",                 limit: 4
      t.integer "c14",                 limit: 4
      t.integer "c15",                 limit: 4
      t.integer "c16",                 limit: 4
      t.integer "c17",                 limit: 4
      t.integer "c18",                 limit: 4
      t.integer "c19",                 limit: 4
      t.integer "c20",                 limit: 4
      t.float   "pe_r",                limit: 24
      t.float   "lpg_r",               limit: 24
      t.float   "cf_r",                limit: 24
      t.float   "gm_r",                limit: 24
      t.float   "wst_r",               limit: 24
      t.float   "div_r",               limit: 24
      t.boolean "country_usa",         limit: 1,                            default: false, null: false
      t.boolean "country_can",         limit: 1,                            default: false, null: false
      t.boolean "country_isr",         limit: 1,                            default: false, null: false
      t.boolean "country_chn",         limit: 1,                            default: false, null: false
      t.boolean "country_others",      limit: 1,                            default: false, null: false
      t.boolean "country_hkg",         limit: 1,                            default: false,              comment: "香港"
      t.boolean "capitalization_pe10", limit: 1,                            default: false,              comment: "PE < 10"
      t.boolean "capitalization_dy4",  limit: 1,                            default: false,              comment: "股息收益率 > 4%"
      t.boolean "capitalization_clb",  limit: 1,                            default: false,              comment: "市值低于账面价值"
      t.boolean "capitalization_cl1s", limit: 1,                            default: false,              comment: "市值低于1倍销售额"
      t.boolean "capitalization_cl7p", limit: 1,                            default: false,              comment: "市值低于7倍经营利润"
      t.decimal "wst_2",                           precision: 18, scale: 6, default: 0.0,                comment: "华尔街目标价格，wst为比例"
      t.decimal "div_2",                           precision: 18, scale: 6, default: 0.0,                comment: "现金分红，div为比例"
      t.decimal "change_rate",                     precision: 10, scale: 6, default: 0.0
      t.datetime "sync_time"

      t.timestamps null: false
    end
  end
end
