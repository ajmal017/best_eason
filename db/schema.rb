# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151127083350) do

  create_table "abbrev_counts", force: :cascade do |t|
    t.string   "abbrev",          limit: 255
    t.integer  "sequence_number", limit: 4
    t.string   "category",        limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "account_analyses", force: :cascade do |t|
    t.integer  "user_id",             limit: 4
    t.integer  "trading_account_id",  limit: 4
    t.integer  "year",                limit: 4
    t.float    "profit",              limit: 24
    t.integer  "buy_count",           limit: 4
    t.integer  "sell_count",          limit: 4
    t.float    "avg_month_trade",     limit: 24
    t.string   "focus_industry",      limit: 255, comment: "重点关注行业"
    t.integer  "cleared_stock_count", limit: 4,   comment: "清仓股票"
    t.float    "win_rate",            limit: 24,  comment: "胜率"
    t.integer  "earned_stocks_count", limit: 4,   comment: "挣钱股票"
    t.integer  "lossed_stocks_count", limit: 4,   comment: "赔钱股票"
    t.float    "avg_holded_days",     limit: 24,  comment: "平均持有时间"
    t.string   "holding_terms",       limit: 255, comment: "短线、中长线、长线"
    t.string   "stock_earn",          limit: 255, comment: "盈亏额最高、最低"
    t.string   "stock_holded_days",   limit: 255, comment: "持有时间最长、最短"
    t.string   "stock_spend",         limit: 255, comment: "投入金额最多、最少"
    t.float    "total_buyed",         limit: 24,  comment: "累计买入"
    t.float    "total_selled",        limit: 24,  comment: "累计卖出"
    t.string   "industries",          limit: 255, comment: "投资分布：行业"
    t.string   "market_distribution", limit: 255, comment: "主板、创业板"
    t.string   "orientation",         limit: 255, comment: "投资方向"
    t.string   "concern",             limit: 255, comment: "投资关注"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_analyses", ["trading_account_id", "year"], name: "index_account_analyses_on_trading_account_id_and_year", using: :btree

  create_table "account_position_risks", force: :cascade do |t|
    t.float    "stock_focus_score",    limit: 24
    t.float    "industry_focus_score", limit: 24
    t.float    "plate_focus_score",    limit: 24
    t.integer  "trading_account_id",   limit: 4
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "var95",                limit: 24
    t.float    "basket_fluctuation",   limit: 24
  end

  add_index "account_position_risks", ["trading_account_id", "date"], name: "index_account_position_risks_on_trading_account_id_and_date", using: :btree

  create_table "account_ranks", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "trading_account_id", limit: 4
    t.string   "rank_type",          limit: 255
    t.float    "property",           limit: 24
    t.decimal  "percent",                        precision: 10, scale: 5
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "broker_id",          limit: 4
    t.float    "profit",             limit: 24,                           default: 0.0
    t.boolean  "ordered",                                                 default: false
  end

  add_index "account_ranks", ["rank_type"], name: "index_account_ranks_on_rank_type", length: {"rank_type"=>6}, using: :btree
  add_index "account_ranks", ["trading_account_id", "rank_type"], name: "idx_account_ranks_type_ta_id", unique: true, length: {"trading_account_id"=>nil, "rank_type"=>6}, using: :btree

  create_table "account_value_archives", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "broker_user_id",     limit: 255
    t.string   "key",                limit: 255
    t.string   "currency",           limit: 255
    t.decimal  "value",                          precision: 16, scale: 2
    t.integer  "user_binding_id",    limit: 4
    t.date     "archive_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "base_currency",      limit: 255
    t.integer  "trading_account_id", limit: 4
  end

  add_index "account_value_archives", ["archive_date"], name: "index_account_value_archives_on_archive_date", using: :btree
  add_index "account_value_archives", ["trading_account_id"], name: "index_account_value_archives_on_trading_account_id", using: :btree
  add_index "account_value_archives", ["user_id", "trading_account_id", "key", "currency", "archive_date"], name: "unique_index_for_account_value_archives", unique: true, using: :btree
  add_index "account_value_archives", ["user_id"], name: "index_account_value_archives_on_user_id", using: :btree

  create_table "account_values", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "broker_user_id",     limit: 255
    t.string   "key",                limit: 255
    t.string   "currency",           limit: 255
    t.decimal  "value",                          precision: 16, scale: 2
    t.integer  "user_binding_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "trading_account_id", limit: 4
  end

  add_index "account_values", ["trading_account_id", "key", "currency"], name: "index_account_values_on_trading_account_id_and_key_and_currency", unique: true, using: :btree
  add_index "account_values", ["trading_account_id"], name: "index_account_values_on_trading_account_id", using: :btree

  create_table "active_docks", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.string   "short_id",    limit: 50
    t.text     "dock_date",   limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "activities", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.string   "type",              limit: 255
    t.integer  "feed_id",           limit: 4
    t.integer  "followed_user_id",  limit: 4
    t.integer  "entry_id",          limit: 4
    t.text     "content",           limit: 65535
    t.integer  "following_user_id", limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "admin_logs", force: :cascade do |t|
    t.integer  "staffer_id", limit: 4
    t.string   "content",    limit: 255
    t.string   "log_type",   limit: 255
    t.string   "request_ip", limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "resource",   limit: 255
  end

  create_table "api_staffer_tokens", force: :cascade do |t|
    t.string   "access_token", limit: 255,                null: false
    t.datetime "expires_at"
    t.integer  "staffer_id",   limit: 4,                  null: false
    t.boolean  "active",                   default: true, null: false
    t.string   "sn_code",      limit: 255
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "api_tokens", force: :cascade do |t|
    t.string   "access_token", limit: 255,                null: false
    t.datetime "expires_at"
    t.integer  "user_id",      limit: 4,                  null: false
    t.boolean  "active",                   default: true, null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "sn_code",      limit: 255
  end

  add_index "api_tokens", ["access_token"], name: "index_api_tokens_on_access_token", using: :btree
  add_index "api_tokens", ["user_id"], name: "index_api_tokens_on_user_id", using: :btree

  create_table "app_permissions", force: :cascade do |t|
    t.integer "user_id",               limit: 4
    t.boolean "all_following_stocks",            default: true, null: false
    t.boolean "all_position_scale",              default: true, null: false
    t.boolean "friend_position_scale",           default: true, null: false
  end

  create_table "article_stocks", force: :cascade do |t|
    t.integer  "article_id", limit: 4
    t.integer  "stock_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "article_stocks", ["article_id", "stock_id"], name: "index_article_stocks_on_article_id_and_stock_id", unique: true, using: :btree
  add_index "article_stocks", ["stock_id"], name: "index_article_stocks_on_stock_id", using: :btree

  create_table "articles", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.string   "img",             limit: 255
    t.text     "content",         limit: 16777215
    t.date     "post_date"
    t.string   "post_user",       limit: 255
    t.string   "url",             limit: 255
    t.text     "remote_img_urls", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "related_stocks",  limit: 65535
    t.text     "related_baskets", limit: 65535
    t.integer  "views_count",     limit: 4
    t.integer  "comments_count",  limit: 4
    t.boolean  "viewable",                         default: true
    t.boolean  "synchronized",                     default: false
    t.text     "abstract",        limit: 65535
    t.integer  "user_id",         limit: 4
    t.integer  "follows_count",   limit: 4,        default: 0
  end

  add_index "articles", ["title"], name: "index_articles_on_title", unique: true, using: :btree

  create_table "bar_minutes", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.string   "symbol",        limit: 30
    t.decimal  "price",                    precision: 12, scale: 3
    t.integer  "volume",        limit: 4
    t.datetime "trade_time"
  end

  create_table "bar_ten_minutes", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.string   "symbol",        limit: 30
    t.decimal  "price",                    precision: 12, scale: 3
    t.integer  "volume",        limit: 4
    t.datetime "trade_time"
  end

  create_table "base_stocks", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "c_name",                 limit: 255
    t.string   "symbol",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "exchange",               limit: 255
    t.string   "ib_symbol",              limit: 255
    t.integer  "board_lot",              limit: 4
    t.string   "data_source",            limit: 255
    t.boolean  "qualified",                                                   default: false
    t.string   "stock_type",             limit: 255
    t.string   "abbrev",                 limit: 255
    t.string   "ticker",                 limit: 255
    t.integer  "ib_id",                  limit: 4
    t.date     "ib_last_date"
    t.integer  "follows_count",          limit: 4,                            default: 0
    t.string   "img",                    limit: 255
    t.date     "archive_date"
    t.decimal  "last_price",                         precision: 16, scale: 2
    t.string   "sector",                 limit: 255
    t.string   "industry",               limit: 255
    t.float    "one_month_return",       limit: 24,                           default: 0.0
    t.float    "six_month_return",       limit: 24,                           default: 0.0
    t.float    "one_year_return",        limit: 24,                           default: 0.0
    t.decimal  "market_value",                       precision: 20, scale: 3, default: 0.0
    t.decimal  "ten_day_avg",                        precision: 16, scale: 2, default: 0.0
    t.decimal  "rt_price",                           precision: 16, scale: 4, default: 0.0
    t.string   "xignite_symbol",         limit: 30
    t.boolean  "normal",                                                      default: true
    t.integer  "three_month_volume_avg", limit: 8,                            default: 0
    t.integer  "thirty_days_volume_avg", limit: 8,                            default: 0
    t.string   "type",                   limit: 255
    t.integer  "inner_code",             limit: 4
    t.integer  "listed_state",           limit: 4
    t.integer  "company_code",           limit: 4
    t.integer  "sector_code",            limit: 4
    t.float    "five_day_return",        limit: 24
    t.string   "chi_spelling",           limit: 255
    t.decimal  "yesterday_price",                    precision: 16, scale: 3
    t.integer  "comments_count",         limit: 4,                            default: 0
    t.integer  "listed_sector",          limit: 4
    t.string   "currency",               limit: 255
    t.decimal  "dividend",                           precision: 18, scale: 6, default: 0.0
    t.string   "short_name",             limit: 255
    t.float    "bullish_percent",        limit: 24,                           default: 0.0
    t.float    "bearish_percent",        limit: 24,                           default: 0.0
  end

  add_index "base_stocks", ["ib_last_date"], name: "index_base_stocks_on_ib_last_date", using: :btree
  add_index "base_stocks", ["inner_code"], name: "index_base_stocks_on_inner_code", unique: true, using: :btree
  add_index "base_stocks", ["listed_state"], name: "index_base_stocks_on_listed_state", using: :btree
  add_index "base_stocks", ["sector_code"], name: "index_base_stocks_on_sector_code", using: :btree
  add_index "base_stocks", ["ticker"], name: "index_base_stocks_on_ticker", using: :btree
  add_index "base_stocks", ["type"], name: "index_base_stocks_on_type", using: :btree
  add_index "base_stocks", ["xignite_symbol"], name: "index_base_stocks_on_xignite_symbol", using: :btree

  create_table "base_stocks_20150316", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "c_name",                 limit: 255
    t.string   "symbol",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "exchange",               limit: 255
    t.string   "ib_symbol",              limit: 255
    t.integer  "board_lot",              limit: 4
    t.string   "data_source",            limit: 255
    t.boolean  "qualified",                                                   default: false
    t.string   "stock_type",             limit: 255
    t.string   "abbrev",                 limit: 255
    t.string   "ticker",                 limit: 255
    t.integer  "ib_id",                  limit: 4
    t.date     "date"
    t.integer  "follows_count",          limit: 4,                            default: 0
    t.string   "img",                    limit: 255
    t.date     "archive_date"
    t.decimal  "last_price",                         precision: 16, scale: 2
    t.string   "sector",                 limit: 255
    t.string   "industry",               limit: 255
    t.decimal  "one_month_return",                   precision: 13, scale: 8, default: 0.0
    t.decimal  "six_month_return",                   precision: 13, scale: 8, default: 0.0
    t.decimal  "one_year_return",                    precision: 13, scale: 8, default: 0.0
    t.decimal  "market_value",                       precision: 20, scale: 3, default: 0.0
    t.decimal  "ten_day_avg",                        precision: 16, scale: 2, default: 0.0
    t.decimal  "rt_price",                           precision: 16, scale: 4, default: 0.0
    t.string   "xignite_symbol",         limit: 30
    t.boolean  "normal",                                                      default: true
    t.integer  "three_month_volume_avg", limit: 8,                            default: 0
    t.integer  "thirty_days_volume_avg", limit: 8,                            default: 0
    t.string   "type",                   limit: 255
    t.integer  "inner_code",             limit: 4
    t.integer  "listed_state",           limit: 4
    t.integer  "company_code",           limit: 4
    t.integer  "sector_code",            limit: 4
    t.float    "five_day_return",        limit: 24
  end

  add_index "base_stocks_20150316", ["date"], name: "index_base_stocks_on_date", using: :btree
  add_index "base_stocks_20150316", ["inner_code"], name: "index_base_stocks_on_inner_code", unique: true, using: :btree
  add_index "base_stocks_20150316", ["listed_state"], name: "index_base_stocks_on_listed_state", using: :btree
  add_index "base_stocks_20150316", ["sector_code"], name: "index_base_stocks_on_sector_code", using: :btree
  add_index "base_stocks_20150316", ["ticker"], name: "index_base_stocks_on_ticker", using: :btree
  add_index "base_stocks_20150316", ["type"], name: "index_base_stocks_on_type", using: :btree
  add_index "base_stocks_20150316", ["xignite_symbol"], name: "index_base_stocks_on_xignite_symbol", using: :btree

  create_table "basket_adjust_logs", force: :cascade do |t|
    t.integer  "basket_adjustment_id", limit: 4
    t.integer  "stock_id",             limit: 4
    t.integer  "action",               limit: 4
    t.decimal  "weight_from",                     precision: 6, scale: 4
    t.decimal  "weight_to",                       precision: 6, scale: 4
    t.float    "stock_price",          limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "realtime_weight_from",            precision: 8, scale: 6
    t.integer  "stock_state",          limit: 4
  end

  add_index "basket_adjust_logs", ["basket_adjustment_id", "stock_id"], name: "index_basket_adjust_logs_on_basket_adjustment_id_and_stock_id", unique: true, using: :btree

  create_table "basket_adjustments", force: :cascade do |t|
    t.integer  "prev_basket_id",     limit: 4
    t.integer  "next_basket_id",     limit: 4
    t.integer  "original_basket_id", limit: 4
    t.text     "reason",             limit: 65535
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "state",              limit: 4,     default: 0
  end

  add_index "basket_adjustments", ["next_basket_id", "state"], name: "index_basket_adjustments_on_next_basket_id_and_state", using: :btree
  add_index "basket_adjustments", ["original_basket_id"], name: "index_basket_adjustments_on_original_basket_id", using: :btree

  create_table "basket_audits", force: :cascade do |t|
    t.integer  "basket_id",     limit: 4
    t.integer  "category",      limit: 4
    t.string   "unpass_reason", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "admin_id",      limit: 4
    t.integer  "state",         limit: 4,   default: 0
  end

  create_table "basket_indices", force: :cascade do |t|
    t.integer  "basket_id",          limit: 4
    t.date     "date"
    t.decimal  "index",                        precision: 10, scale: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "index_without_cash",           precision: 10, scale: 4
  end

  add_index "basket_indices", ["basket_id"], name: "index_basket_indices_on_basket_id", using: :btree
  add_index "basket_indices", ["date"], name: "index_basket_indices_on_date", using: :btree

  create_table "basket_opinions", force: :cascade do |t|
    t.integer  "basket_id",          limit: 4
    t.integer  "user_id",            limit: 4
    t.integer  "opinion",            limit: 4
    t.datetime "post_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "original_basket_id", limit: 4
  end

  add_index "basket_opinions", ["opinion"], name: "index_basket_opinions_on_opinion", using: :btree
  add_index "basket_opinions", ["user_id", "basket_id", "original_basket_id"], name: "idx_basket_opinions_of_user_basket_original_basket_id", using: :btree

  create_table "basket_ranks", force: :cascade do |t|
    t.integer "basket_id",          limit: 4
    t.float   "ret",                limit: 24
    t.integer "contest_id",         limit: 4
    t.float   "one_day_ret",        limit: 24
    t.integer "prev_rank",          limit: 4
    t.integer "status",             limit: 4
    t.integer "now_rank",           limit: 4
    t.integer "user_id",            limit: 4
    t.float   "position_percent",   limit: 24, default: 0.0
    t.float   "win_rate",           limit: 24, default: 0.0
    t.integer "adjust_count",       limit: 4,  default: 0
    t.integer "trading_account_id", limit: 4
  end

  add_index "basket_ranks", ["basket_id", "contest_id"], name: "index_basket_ranks_on_basket_id_and_contest_id", using: :btree
  add_index "basket_ranks", ["trading_account_id"], name: "index_basket_ranks_on_trading_account_id", using: :btree
  add_index "basket_ranks", ["user_id"], name: "index_basket_ranks_on_user_id", using: :btree

  create_table "basket_stock_snapshots", force: :cascade do |t|
    t.integer  "basket_id",            limit: 4
    t.integer  "stock_id",             limit: 4
    t.integer  "basket_adjustment_id", limit: 4
    t.decimal  "weight",                             precision: 6,  scale: 4
    t.float    "stock_price",          limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "change_percent",       limit: 24,                              default: 0.0
    t.integer  "next_basket_id",       limit: 4
    t.text     "notes",                limit: 65535
    t.decimal  "adjusted_weight",                    precision: 20, scale: 18
    t.decimal  "ori_weight",                         precision: 6,  scale: 4
  end

  add_index "basket_stock_snapshots", ["basket_id", "next_basket_id"], name: "index_basket_stock_snapshots_on_basket_id_and_next_basket_id", using: :btree
  add_index "basket_stock_snapshots", ["basket_id", "stock_id", "basket_adjustment_id"], name: "index_bss_on_basket_and_stock_and_adjustment_id", unique: true, using: :btree

  create_table "basket_stocks", force: :cascade do |t|
    t.integer  "stock_id",        limit: 4
    t.integer  "basket_id",       limit: 4
    t.decimal  "weight",                      precision: 10, scale: 4
    t.string   "notes",           limit: 320
    t.decimal  "adjusted_weight",             precision: 20, scale: 18
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "ori_weight",                  precision: 6,  scale: 4
    t.integer  "real_share",      limit: 4,                             default: 0
  end

  add_index "basket_stocks", ["basket_id"], name: "index_basket_stocks_on_basket_id", using: :btree
  add_index "basket_stocks", ["stock_id"], name: "index_basket_stocks_on_stock_id", using: :btree

  create_table "basket_stocks_2", force: :cascade do |t|
    t.integer  "stock_id",        limit: 4
    t.integer  "basket_id",       limit: 4
    t.decimal  "weight",                      precision: 10, scale: 4
    t.string   "notes",           limit: 320
    t.decimal  "adjusted_weight",             precision: 20, scale: 18
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "ori_weight",                  precision: 6,  scale: 4
  end

  add_index "basket_stocks_2", ["basket_id"], name: "index_basket_stocks_on_basket_id", using: :btree
  add_index "basket_stocks_2", ["stock_id"], name: "index_basket_stocks_on_stock_id", using: :btree

  create_table "basket_stocks_copy", force: :cascade do |t|
    t.integer  "stock_id",        limit: 4
    t.integer  "basket_id",       limit: 4
    t.decimal  "weight",                      precision: 10, scale: 4
    t.string   "notes",           limit: 320
    t.decimal  "adjusted_weight",             precision: 20, scale: 18
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "ori_weight",                  precision: 6,  scale: 4
  end

  add_index "basket_stocks_copy", ["basket_id"], name: "index_basket_stocks_on_basket_id", using: :btree
  add_index "basket_stocks_copy", ["stock_id"], name: "index_basket_stocks_on_stock_id", using: :btree

  create_table "basket_weight_logs", force: :cascade do |t|
    t.integer "stock_id",        limit: 4
    t.integer "basket_id",       limit: 4
    t.decimal "adjusted_weight",           precision: 20, scale: 18
    t.date    "date"
  end

  add_index "basket_weight_logs", ["basket_id", "date"], name: "index_basket_weight_logs_on_basket_id_and_date", using: :btree
  add_index "basket_weight_logs", ["basket_id"], name: "index_basket_weight_logs_on_basket_id", using: :btree
  add_index "basket_weight_logs", ["date"], name: "index_basket_weight_logs_on_date", using: :btree

  create_table "baskets", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "description",        limit: 65535
    t.integer  "author_id",          limit: 4
    t.string   "img",                limit: 255
    t.string   "segment",            limit: 255
    t.datetime "start_on"
    t.integer  "scope",              limit: 4
    t.boolean  "custom"
    t.integer  "category",           limit: 4
    t.integer  "original_id",        limit: 4
    t.text     "abbrev",             limit: 65535
    t.integer  "state",              limit: 4,                              default: 1
    t.boolean  "third_party",                                               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "one_day_return",                   precision: 13, scale: 8
    t.decimal  "one_month_return",                 precision: 13, scale: 8
    t.decimal  "one_year_return",                  precision: 13, scale: 8
    t.integer  "follows_count",      limit: 4,                              default: 0
    t.float    "bullish_percent",    limit: 24,                             default: 0.0
    t.float    "hot_score",          limit: 24,                             default: 0.0
    t.decimal  "three_month_return",               precision: 13, scale: 8
    t.integer  "comments_count",     limit: 4
    t.integer  "views_count",        limit: 4,                              default: 0
    t.integer  "orders_count",       limit: 4,                              default: 0
    t.integer  "likes_count",        limit: 4
    t.datetime "modified_at"
    t.boolean  "visible",                                                   default: false
    t.boolean  "recommend",                                                 default: false
    t.decimal  "orders_total_money",               precision: 16, scale: 4, default: 0.0
    t.string   "type",               limit: 255
    t.integer  "parent_id",          limit: 4
    t.date     "archive_date"
    t.decimal  "total_return",                     precision: 13, scale: 8
    t.string   "market",             limit: 255
    t.float    "bearish_percent",    limit: 24,                             default: 0.0
    t.integer  "latest_history_id",  limit: 4
    t.integer  "contest",            limit: 4,                              default: 0,     comment: "是否报名参加比赛"
  end

  add_index "baskets", ["author_id"], name: "index_baskets_on_author_id", using: :btree
  add_index "baskets", ["contest"], name: "index_baskets_on_contest", using: :btree
  add_index "baskets", ["latest_history_id"], name: "index_baskets_on_latest_history_id", using: :btree
  add_index "baskets", ["market"], name: "index_baskets_on_market", using: :btree
  add_index "baskets", ["orders_count"], name: "index_baskets_on_orders_count", using: :btree
  add_index "baskets", ["original_id"], name: "index_baskets_on_original_id", using: :btree
  add_index "baskets", ["parent_id"], name: "index_baskets_on_parent_id", using: :btree
  add_index "baskets", ["state"], name: "index_baskets_on_state", using: :btree
  add_index "baskets", ["title"], name: "index_baskets_on_title", using: :btree
  add_index "baskets", ["type"], name: "index_baskets_on_type", using: :btree

  create_table "baskets_2", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "description",        limit: 65535
    t.integer  "author_id",          limit: 4
    t.string   "img",                limit: 255
    t.string   "segment",            limit: 255
    t.datetime "start_on"
    t.integer  "scope",              limit: 4
    t.boolean  "custom"
    t.integer  "category",           limit: 4
    t.integer  "original_id",        limit: 4
    t.text     "abbrev",             limit: 65535
    t.integer  "state",              limit: 4,                              default: 1
    t.boolean  "third_party",                                               default: true
    t.boolean  "weight_changed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "one_day_return",                   precision: 13, scale: 8
    t.decimal  "one_month_return",                 precision: 13, scale: 8
    t.decimal  "one_year_return",                  precision: 13, scale: 8
    t.integer  "follows_count",      limit: 4,                              default: 0
    t.float    "bullish_percent",    limit: 24,                             default: 0.0
    t.float    "hot_score",          limit: 24,                             default: 0.0
    t.decimal  "three_month_return",               precision: 13, scale: 8
    t.integer  "topic_id",           limit: 4
    t.integer  "comments_count",     limit: 4
    t.integer  "views_count",        limit: 4,                              default: 0
    t.integer  "orders_count",       limit: 4,                              default: 0
    t.integer  "likes_count",        limit: 4
    t.datetime "modified_at"
    t.boolean  "visible",                                                   default: false
    t.boolean  "recommend",                                                 default: false
    t.decimal  "orders_total_money",               precision: 16, scale: 4, default: 0.0
    t.string   "type",               limit: 255
    t.integer  "parent_id",          limit: 4
    t.date     "archive_date"
    t.float    "bearish_percent",    limit: 24,                             default: 0.0
  end

  add_index "baskets_2", ["author_id"], name: "index_baskets_on_author_id", using: :btree
  add_index "baskets_2", ["orders_count"], name: "index_baskets_on_orders_count", using: :btree
  add_index "baskets_2", ["original_id"], name: "index_baskets_on_original_id", using: :btree
  add_index "baskets_2", ["parent_id"], name: "index_baskets_on_parent_id", using: :btree
  add_index "baskets_2", ["state"], name: "index_baskets_on_state", using: :btree
  add_index "baskets_2", ["title"], name: "index_baskets_on_title", using: :btree
  add_index "baskets_2", ["type"], name: "index_baskets_on_type", using: :btree
  add_index "baskets_2", ["weight_changed"], name: "index_baskets_on_weight_changed", using: :btree

  create_table "baskets_copy", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "description",        limit: 65535
    t.integer  "author_id",          limit: 4
    t.string   "img",                limit: 255
    t.string   "segment",            limit: 255
    t.datetime "start_on"
    t.integer  "scope",              limit: 4
    t.boolean  "custom"
    t.integer  "category",           limit: 4
    t.integer  "original_id",        limit: 4
    t.text     "abbrev",             limit: 65535
    t.integer  "state",              limit: 4,                              default: 1
    t.boolean  "third_party",                                               default: true
    t.boolean  "weight_changed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "one_day_return",                   precision: 13, scale: 8
    t.decimal  "one_month_return",                 precision: 13, scale: 8
    t.decimal  "one_year_return",                  precision: 13, scale: 8
    t.integer  "follows_count",      limit: 4,                              default: 0
    t.float    "bullish_percent",    limit: 24,                             default: 0.0
    t.float    "hot_score",          limit: 24,                             default: 0.0
    t.decimal  "three_month_return",               precision: 13, scale: 8
    t.integer  "topic_id",           limit: 4
    t.integer  "comments_count",     limit: 4
    t.integer  "views_count",        limit: 4,                              default: 0
    t.integer  "orders_count",       limit: 4,                              default: 0
    t.integer  "likes_count",        limit: 4
    t.datetime "modified_at"
    t.boolean  "visible",                                                   default: false
    t.boolean  "recommend",                                                 default: false
    t.decimal  "orders_total_money",               precision: 16, scale: 4, default: 0.0
    t.string   "type",               limit: 255
    t.integer  "parent_id",          limit: 4
    t.date     "archive_date"
    t.float    "bearish_percent",    limit: 24,                             default: 0.0
  end

  add_index "baskets_copy", ["author_id"], name: "index_baskets_on_author_id", using: :btree
  add_index "baskets_copy", ["orders_count"], name: "index_baskets_on_orders_count", using: :btree
  add_index "baskets_copy", ["original_id"], name: "index_baskets_on_original_id", using: :btree
  add_index "baskets_copy", ["parent_id"], name: "index_baskets_on_parent_id", using: :btree
  add_index "baskets_copy", ["state"], name: "index_baskets_on_state", using: :btree
  add_index "baskets_copy", ["title"], name: "index_baskets_on_title", using: :btree
  add_index "baskets_copy", ["type"], name: "index_baskets_on_type", using: :btree
  add_index "baskets_copy", ["weight_changed"], name: "index_baskets_on_weight_changed", using: :btree

  create_table "baskets_copy2", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "description",        limit: 65535
    t.integer  "author_id",          limit: 4
    t.string   "img",                limit: 255
    t.string   "segment",            limit: 255
    t.datetime "start_on"
    t.integer  "scope",              limit: 4
    t.boolean  "custom"
    t.integer  "category",           limit: 4
    t.integer  "original_id",        limit: 4
    t.text     "abbrev",             limit: 65535
    t.integer  "state",              limit: 4,                              default: 1
    t.boolean  "third_party",                                               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "one_day_return",                   precision: 13, scale: 8
    t.decimal  "one_month_return",                 precision: 13, scale: 8
    t.decimal  "one_year_return",                  precision: 13, scale: 8
    t.integer  "follows_count",      limit: 4,                              default: 0
    t.float    "bullish_percent",    limit: 24,                             default: 0.0
    t.float    "hot_score",          limit: 24,                             default: 0.0
    t.decimal  "three_month_return",               precision: 13, scale: 8
    t.integer  "comments_count",     limit: 4
    t.integer  "views_count",        limit: 4,                              default: 0
    t.integer  "orders_count",       limit: 4,                              default: 0
    t.integer  "likes_count",        limit: 4
    t.datetime "modified_at"
    t.boolean  "visible",                                                   default: false
    t.boolean  "recommend",                                                 default: false
    t.decimal  "orders_total_money",               precision: 16, scale: 4, default: 0.0
    t.string   "type",               limit: 255
    t.integer  "parent_id",          limit: 4
    t.date     "archive_date"
    t.decimal  "total_return",                     precision: 13, scale: 8
    t.string   "market",             limit: 255
    t.float    "bearish_percent",    limit: 24,                             default: 0.0
  end

  add_index "baskets_copy2", ["author_id"], name: "index_baskets_on_author_id", using: :btree
  add_index "baskets_copy2", ["market"], name: "index_baskets_on_market", using: :btree
  add_index "baskets_copy2", ["orders_count"], name: "index_baskets_on_orders_count", using: :btree
  add_index "baskets_copy2", ["original_id"], name: "index_baskets_on_original_id", using: :btree
  add_index "baskets_copy2", ["parent_id"], name: "index_baskets_on_parent_id", using: :btree
  add_index "baskets_copy2", ["state"], name: "index_baskets_on_state", using: :btree
  add_index "baskets_copy2", ["title"], name: "index_baskets_on_title", using: :btree
  add_index "baskets_copy2", ["type"], name: "index_baskets_on_type", using: :btree

  create_table "baskets_copy3", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "description",        limit: 65535
    t.integer  "author_id",          limit: 4
    t.string   "img",                limit: 255
    t.string   "segment",            limit: 255
    t.datetime "start_on"
    t.integer  "scope",              limit: 4
    t.boolean  "custom"
    t.integer  "category",           limit: 4
    t.integer  "original_id",        limit: 4
    t.text     "abbrev",             limit: 65535
    t.integer  "state",              limit: 4,                              default: 1
    t.boolean  "third_party",                                               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "one_day_return",                   precision: 13, scale: 8
    t.decimal  "one_month_return",                 precision: 13, scale: 8
    t.decimal  "one_year_return",                  precision: 13, scale: 8
    t.integer  "follows_count",      limit: 4,                              default: 0
    t.float    "bullish_percent",    limit: 24,                             default: 0.0
    t.float    "hot_score",          limit: 24,                             default: 0.0
    t.decimal  "three_month_return",               precision: 13, scale: 8
    t.integer  "comments_count",     limit: 4
    t.integer  "views_count",        limit: 4,                              default: 0
    t.integer  "orders_count",       limit: 4,                              default: 0
    t.integer  "likes_count",        limit: 4
    t.datetime "modified_at"
    t.boolean  "visible",                                                   default: false
    t.boolean  "recommend",                                                 default: false
    t.decimal  "orders_total_money",               precision: 16, scale: 4, default: 0.0
    t.string   "type",               limit: 255
    t.integer  "parent_id",          limit: 4
    t.date     "archive_date"
    t.decimal  "total_return",                     precision: 13, scale: 8
    t.string   "market",             limit: 255
    t.float    "bearish_percent",    limit: 24,                             default: 0.0
  end

  add_index "baskets_copy3", ["author_id"], name: "index_baskets_on_author_id", using: :btree
  add_index "baskets_copy3", ["market"], name: "index_baskets_on_market", using: :btree
  add_index "baskets_copy3", ["orders_count"], name: "index_baskets_on_orders_count", using: :btree
  add_index "baskets_copy3", ["original_id"], name: "index_baskets_on_original_id", using: :btree
  add_index "baskets_copy3", ["parent_id"], name: "index_baskets_on_parent_id", using: :btree
  add_index "baskets_copy3", ["state"], name: "index_baskets_on_state", using: :btree
  add_index "baskets_copy3", ["title"], name: "index_baskets_on_title", using: :btree
  add_index "baskets_copy3", ["type"], name: "index_baskets_on_type", using: :btree

  create_table "baskets_copy5", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "description",        limit: 65535
    t.integer  "author_id",          limit: 4
    t.string   "img",                limit: 255
    t.string   "segment",            limit: 255
    t.datetime "start_on"
    t.integer  "scope",              limit: 4
    t.boolean  "custom"
    t.integer  "category",           limit: 4
    t.integer  "original_id",        limit: 4
    t.text     "abbrev",             limit: 65535
    t.integer  "state",              limit: 4,                              default: 1
    t.boolean  "third_party",                                               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "one_day_return",                   precision: 13, scale: 8
    t.decimal  "one_month_return",                 precision: 13, scale: 8
    t.decimal  "one_year_return",                  precision: 13, scale: 8
    t.integer  "follows_count",      limit: 4,                              default: 0
    t.float    "bullish_percent",    limit: 24,                             default: 0.0
    t.float    "hot_score",          limit: 24,                             default: 0.0
    t.decimal  "three_month_return",               precision: 13, scale: 8
    t.integer  "comments_count",     limit: 4
    t.integer  "views_count",        limit: 4,                              default: 0
    t.integer  "orders_count",       limit: 4,                              default: 0
    t.integer  "likes_count",        limit: 4
    t.datetime "modified_at"
    t.boolean  "visible",                                                   default: false
    t.boolean  "recommend",                                                 default: false
    t.decimal  "orders_total_money",               precision: 16, scale: 4, default: 0.0
    t.string   "type",               limit: 255
    t.integer  "parent_id",          limit: 4
    t.date     "archive_date"
    t.decimal  "total_return",                     precision: 13, scale: 8
    t.string   "market",             limit: 255
    t.float    "bearish_percent",    limit: 24,                             default: 0.0
  end

  add_index "baskets_copy5", ["author_id"], name: "index_baskets_on_author_id", using: :btree
  add_index "baskets_copy5", ["market"], name: "index_baskets_on_market", using: :btree
  add_index "baskets_copy5", ["orders_count"], name: "index_baskets_on_orders_count", using: :btree
  add_index "baskets_copy5", ["original_id"], name: "index_baskets_on_original_id", using: :btree
  add_index "baskets_copy5", ["parent_id"], name: "index_baskets_on_parent_id", using: :btree
  add_index "baskets_copy5", ["state"], name: "index_baskets_on_state", using: :btree
  add_index "baskets_copy5", ["title"], name: "index_baskets_on_title", using: :btree
  add_index "baskets_copy5", ["type"], name: "index_baskets_on_type", using: :btree

  create_table "baskets_office", force: :cascade do |t|
    t.string   "title",              limit: 255
    t.text     "description",        limit: 65535
    t.integer  "author_id",          limit: 4
    t.string   "img",                limit: 255
    t.string   "segment",            limit: 255
    t.datetime "start_on"
    t.integer  "scope",              limit: 4
    t.boolean  "custom"
    t.integer  "category",           limit: 4
    t.integer  "original_id",        limit: 4
    t.text     "abbrev",             limit: 65535
    t.integer  "state",              limit: 4,                              default: 1
    t.boolean  "third_party",                                               default: true
    t.boolean  "weight_changed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "one_day_return",                   precision: 13, scale: 8
    t.decimal  "one_month_return",                 precision: 13, scale: 8
    t.decimal  "one_year_return",                  precision: 13, scale: 8
    t.integer  "follows_count",      limit: 4,                              default: 0
    t.float    "bullish_percent",    limit: 24,                             default: 0.0
    t.float    "hot_score",          limit: 24,                             default: 0.0
    t.decimal  "three_month_return",               precision: 13, scale: 8
    t.integer  "topic_id",           limit: 4
    t.integer  "comments_count",     limit: 4
    t.integer  "views_count",        limit: 4,                              default: 0
    t.integer  "orders_count",       limit: 4,                              default: 0
    t.integer  "likes_count",        limit: 4
    t.datetime "modified_at"
    t.boolean  "visible",                                                   default: false
    t.boolean  "recommend",                                                 default: false
    t.decimal  "orders_total_money",               precision: 16, scale: 4, default: 0.0
    t.string   "type",               limit: 255
    t.integer  "parent_id",          limit: 4
    t.date     "archive_date"
    t.float    "bearish_percent",    limit: 24,                             default: 0.0
  end

  add_index "baskets_office", ["author_id"], name: "index_baskets_on_author_id", using: :btree
  add_index "baskets_office", ["orders_count"], name: "index_baskets_on_orders_count", using: :btree
  add_index "baskets_office", ["original_id"], name: "index_baskets_on_original_id", using: :btree
  add_index "baskets_office", ["parent_id"], name: "index_baskets_on_parent_id", using: :btree
  add_index "baskets_office", ["state"], name: "index_baskets_on_state", using: :btree
  add_index "baskets_office", ["title"], name: "index_baskets_on_title", using: :btree
  add_index "baskets_office", ["type"], name: "index_baskets_on_type", using: :btree
  add_index "baskets_office", ["weight_changed"], name: "index_baskets_on_weight_changed", using: :btree

  create_table "blogs", force: :cascade do |t|
    t.integer  "tweet_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "brokers", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "cname",                  limit: 255
    t.string   "status",                 limit: 10,  default: "new"
    t.string   "master_account",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "market",                 limit: 255
    t.string   "area",                   limit: 10
    t.string   "logo",                   limit: 255
    t.string   "small_logo",             limit: 255
    t.boolean  "display",                            default: true
    t.integer  "position",               limit: 4
    t.date     "trading_date"
    t.datetime "trading_date_synced_at"
    t.integer  "trading_status",         limit: 4,   default: 0
  end

  add_index "brokers", ["area"], name: "index_brokers_on_area", using: :btree
  add_index "brokers", ["position"], name: "index_brokers_on_position", using: :btree

  create_table "ca_dividends", force: :cascade do |t|
    t.string   "symbol",        limit: 255
    t.string   "amount",        limit: 255
    t.date     "ex_div_date"
    t.date     "record_date"
    t.date     "payable_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base_stock_id", limit: 4
    t.string   "company_name",  limit: 255
  end

  create_table "ca_splits", force: :cascade do |t|
    t.string   "symbol",        limit: 255
    t.string   "factor",        limit: 255
    t.integer  "base_stock_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "company_name",  limit: 255
    t.date     "date"
    t.boolean  "finished",                  default: false
  end

  create_table "categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "code",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "position",   limit: 24,  default: 0.0
  end

  create_table "category_articles", force: :cascade do |t|
    t.integer  "category_id", limit: 4
    t.integer  "article_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "channel_codes", force: :cascade do |t|
    t.string   "code",        limit: 50
    t.string   "apk_url",     limit: 255
    t.integer  "status",      limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description", limit: 255
    t.string   "media",       limit: 50
    t.string   "ad_type",     limit: 50
  end

  add_index "channel_codes", ["code"], name: "channel_codes_code", using: :btree

  create_table "chart_lines", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.text     "content",              limit: 65535
    t.integer  "user_id",              limit: 4
    t.integer  "commentable_id",       limit: 4
    t.string   "commentable_type",     limit: 16
    t.integer  "likes_count",          limit: 4
    t.integer  "comments_count",       limit: 4
    t.boolean  "bullish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "replyable_id",         limit: 4
    t.string   "replyable_type",       limit: 16
    t.boolean  "deleted",                            default: false
    t.string   "top_commentable_id",   limit: 191
    t.string   "top_commentable_type", limit: 30
    t.string   "commentable_ids",      limit: 512
    t.text     "text",                 limit: 65535
    t.text     "body",                 limit: 65535
    t.text     "full_body",            limit: 65535
    t.integer  "root_replyed_id",      limit: 4
    t.text     "root_replyed_body",    limit: 65535
    t.text     "mobile_body",          limit: 65535
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree
  add_index "comments", ["commentable_ids"], name: "index_comments_on_commentable_ids", length: {"commentable_ids"=>120}, using: :btree
  add_index "comments", ["replyable_id", "replyable_type"], name: "index_comments_on_replyable_id_and_replyable_type", using: :btree
  add_index "comments", ["top_commentable_id", "top_commentable_type"], name: "index_comments_on_top_commentable_id_and_top_commentable_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "commission_reports", force: :cascade do |t|
    t.decimal  "commission",                        precision: 16, scale: 4
    t.string   "currency",              limit: 255
    t.string   "exec_id",               limit: 255
    t.string   "realized_pnl",          limit: 255
    t.string   "yield",                 limit: 255
    t.string   "yield_redemption_date", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contest_cashes", force: :cascade do |t|
    t.integer  "contest_id", limit: 4
    t.decimal  "value",                  precision: 16, scale: 2
    t.string   "key",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "contest_cashes", ["contest_id"], name: "index_contest_cashes_on_contest_id", using: :btree

  create_table "contests", force: :cascade do |t|
    t.integer  "status",         limit: 4
    t.string   "name",           limit: 255
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "broker_id",      limit: 4
    t.integer  "users_count",    limit: 4
    t.decimal  "total_invest",               precision: 10
    t.string   "players_csv",    limit: 255
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "comments_count", limit: 4,                  default: 0
  end

  create_table "counters", force: :cascade do |t|
    t.integer  "user_id",                     limit: 4
    t.integer  "unread_comment_count",        limit: 4, default: 0
    t.integer  "unread_like_count",           limit: 4, default: 0
    t.integer  "unread_system_count",         limit: 4, default: 0
    t.integer  "unread_trade_count",          limit: 4, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "unread_message_count",        limit: 4, default: 0
    t.integer  "unread_mention_count",        limit: 4, default: 0
    t.integer  "unread_hongbao_count",        limit: 4, default: 1
    t.integer  "unread_position_count",       limit: 4, default: 0
    t.integer  "unread_stock_reminder_count", limit: 4, default: 0
    t.integer  "unread_globle_count",         limit: 4, default: 0
  end

  add_index "counters", ["user_id"], name: "index_counters_on_user_id", unique: true, using: :btree

  create_table "email_tokens", force: :cascade do |t|
    t.string   "email",                limit: 255
    t.string   "confirmation_token",   limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "invite_code",          limit: 255
    t.string   "channel_code",         limit: 255
  end

  create_table "entries", force: :cascade do |t|
    t.integer  "feed_id",          limit: 4
    t.string   "title",            limit: 255
    t.string   "url",              limit: 255
    t.text     "content",          limit: 65535
    t.datetime "published_date"
    t.integer  "up_votes_count",   limit: 4
    t.integer  "down_votes_count", limit: 4
    t.integer  "comments_count",   limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.decimal  "value",                          precision: 16, scale: 10
    t.string   "currency",           limit: 255
    t.string   "account_name",       limit: 255
    t.integer  "user_binding_id",    limit: 4
    t.integer  "user_id",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "trading_account_id", limit: 4
  end

  add_index "exchange_rates", ["account_name"], name: "index_exchange_rates_on_account_name", using: :btree
  add_index "exchange_rates", ["currency", "account_name"], name: "index_exchange_rates_on_currency_and_account_name", unique: true, using: :btree
  add_index "exchange_rates", ["currency", "user_binding_id"], name: "index_exchange_rates_on_currency_and_user_binding_id", using: :btree
  add_index "exchange_rates", ["currency", "user_id"], name: "index_exchange_rates_on_currency_and_user_id", using: :btree
  add_index "exchange_rates", ["trading_account_id", "currency"], name: "index_exchange_rates_on_trading_account_id_and_currency", using: :btree
  add_index "exchange_rates", ["user_binding_id"], name: "index_exchange_rates_on_user_binding_id", using: :btree
  add_index "exchange_rates", ["user_id"], name: "index_exchange_rates_on_user_id", using: :btree

  create_table "exec_details", force: :cascade do |t|
    t.string   "basket_id",          limit: 255
    t.integer  "order_id",           limit: 4
    t.string   "instance_id",        limit: 255
    t.string   "exchange",           limit: 255
    t.string   "currency",           limit: 255
    t.string   "symbol",             limit: 255
    t.integer  "contract_id",        limit: 4
    t.string   "account_name",       limit: 255
    t.decimal  "avg_price",                      precision: 16, scale: 10
    t.integer  "cum_quantity",       limit: 4
    t.string   "exec_exchange",      limit: 255
    t.string   "exec_id",            limit: 255
    t.string   "ib_order_id",        limit: 255
    t.integer  "perm_id",            limit: 4
    t.decimal  "price",                          precision: 16, scale: 10
    t.integer  "shares",             limit: 4
    t.string   "side",               limit: 255
    t.string   "time",               limit: 255
    t.string   "ev_rule",            limit: 255
    t.decimal  "ex_multiplier",                  precision: 16, scale: 10
    t.boolean  "processed",                                                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",               limit: 255
    t.integer  "user_id",            limit: 4
    t.integer  "stock_id",           limit: 4
    t.integer  "trading_account_id", limit: 4
    t.string   "rt_order_id",        limit: 255
  end

  add_index "exec_details", ["contract_id"], name: "index_exec_details_on_contract_id", using: :btree
  add_index "exec_details", ["exec_id"], name: "index_exec_details_on_exec_id", using: :btree
  add_index "exec_details", ["ib_order_id", "time"], name: "index_exec_details_on_ib_order_id_and_time", using: :btree
  add_index "exec_details", ["ib_order_id"], name: "index_exec_details_on_ib_order_id", using: :btree
  add_index "exec_details", ["stock_id"], name: "index_exec_details_on_stock_id", using: :btree
  add_index "exec_details", ["trading_account_id", "exec_id"], name: "index_exec_details_on_trading_account_id_and_exec_id", unique: true, using: :btree
  add_index "exec_details", ["trading_account_id"], name: "index_exec_details_on_trading_account_id", using: :btree
  add_index "exec_details", ["user_id"], name: "index_exec_details_on_user_id", using: :btree

  create_table "favorites", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "feed_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "favorable_id",   limit: 4
    t.string   "favorable_type", limit: 16
  end

  add_index "favorites", ["favorable_type", "favorable_id"], name: "favorites_favorable_idx", using: :btree
  add_index "favorites", ["feed_id"], name: "index_favorites_on_feed_id", using: :btree
  add_index "favorites", ["user_id"], name: "index_favorites_on_user_id", using: :btree

  create_table "feedbacks", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.text     "content",         limit: 65535
    t.integer  "feed_type",       limit: 4,     default: 0
    t.string   "contact_way",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reportable_type", limit: 255
    t.integer  "reportable_id",   limit: 4
  end

  create_table "feeds", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "url",        limit: 255
    t.string   "feed_url",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "follows", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.integer  "following_id",     limit: 4
    t.boolean  "friend",                         default: false
    t.boolean  "read",                           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "followable_id",    limit: 4
    t.string   "followable_type",  limit: 16
    t.text     "notes",            limit: 65535
    t.float    "sort",             limit: 24
    t.integer  "followed_user_id", limit: 4
    t.float    "price",            limit: 24
    t.float    "ori_price",        limit: 24
    t.string   "type",             limit: 255
  end

  add_index "follows", ["followable_type", "followable_id"], name: "index_follows_on_followable_type_and_followable_id", using: :btree
  add_index "follows", ["followed_user_id"], name: "index_follows_on_followed_user_id", using: :btree
  add_index "follows", ["user_id"], name: "index_follows_on_user_id", using: :btree

  create_table "forbidden_names", force: :cascade do |t|
    t.string "word", limit: 255
  end

  create_table "guess_indices", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.date     "date"
    t.decimal  "index",                precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "guess_indices", ["date"], name: "index_guess_indices_on_date", using: :btree
  add_index "guess_indices", ["user_id"], name: "index_guess_indices_on_user_id", using: :btree

  create_table "historical_quote_cns", force: :cascade do |t|
    t.integer  "base_stock_id",                  limit: 4
    t.string   "symbol",                         limit: 255
    t.decimal  "last",                                       precision: 10, scale: 3
    t.decimal  "open",                                       precision: 10, scale: 3
    t.decimal  "high",                                       precision: 10, scale: 3
    t.decimal  "low",                                        precision: 10, scale: 3
    t.decimal  "last_close",                                 precision: 10, scale: 3
    t.decimal  "change_from_open",                           precision: 9,  scale: 3
    t.decimal  "percent_change_from_open",                   precision: 9,  scale: 3
    t.decimal  "change_from_last_close",                     precision: 9,  scale: 3
    t.decimal  "percent_change_from_last_close",             precision: 9,  scale: 3
    t.decimal  "index",                                      precision: 30, scale: 13
    t.integer  "volume",                         limit: 8
    t.date     "date"
    t.string   "currency",                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "ma10",                                       precision: 10, scale: 3
    t.decimal  "ma5",                                        precision: 10, scale: 3
  end

  add_index "historical_quote_cns", ["base_stock_id", "date", "change_from_last_close", "last"], name: "entire_cflc_for_historical_quote_cns", using: :btree
  add_index "historical_quote_cns", ["base_stock_id", "date"], name: "index_historical_quote_cns_on_base_stock_id_and_date", unique: true, using: :btree
  add_index "historical_quote_cns", ["date"], name: "index_historical_quote_cns_on_date", using: :btree
  add_index "historical_quote_cns", ["symbol"], name: "index_historical_quote_cns_on_symbol", using: :btree

  create_table "historical_quote_prices", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.date     "date"
    t.decimal  "last",                      precision: 10, scale: 3
    t.string   "currency",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "historical_quote_prices", ["base_stock_id", "date"], name: "index_historical_quote_prices_on_base_stock_id_and_date", unique: true, using: :btree

  create_table "historical_quote_resyncs", force: :cascade do |t|
    t.string   "symbol",        limit: 255
    t.integer  "base_stock_id", limit: 4
    t.decimal  "old_last",                  precision: 16, scale: 3
    t.decimal  "new_last",                  precision: 16, scale: 3
    t.boolean  "kline",                                              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "historical_quote_resyncs", ["base_stock_id", "kline"], name: "index_historical_quote_resyncs_on_base_stock_id_and_kline", using: :btree

  create_table "historical_quote_retries", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.date     "date"
    t.date     "trading_date"
    t.integer  "number",        limit: 4, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "historical_quote_retries", ["base_stock_id"], name: "index_historical_quote_retries_on_base_stock_id", using: :btree
  add_index "historical_quote_retries", ["date"], name: "index_historical_quote_retries_on_date", using: :btree

  create_table "historical_quotes", force: :cascade do |t|
    t.integer  "base_stock_id",                  limit: 4
    t.string   "symbol",                         limit: 255
    t.decimal  "last",                                       precision: 10, scale: 3
    t.decimal  "open",                                       precision: 10, scale: 3
    t.decimal  "high",                                       precision: 10, scale: 3
    t.decimal  "low",                                        precision: 10, scale: 3
    t.decimal  "last_close",                                 precision: 10, scale: 3
    t.decimal  "change_from_open",                           precision: 9,  scale: 3
    t.decimal  "percent_change_from_open",                   precision: 9,  scale: 3
    t.decimal  "change_from_last_close",                     precision: 9,  scale: 3
    t.decimal  "percent_change_from_last_close",             precision: 9,  scale: 3
    t.decimal  "index",                                      precision: 30, scale: 13
    t.integer  "volume",                         limit: 8
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency",                       limit: 255
    t.decimal  "ma5",                                        precision: 10, scale: 3
  end

  add_index "historical_quotes", ["base_stock_id", "date"], name: "index_historical_quotes_on_base_stock_id_and_date", unique: true, using: :btree
  add_index "historical_quotes", ["base_stock_id", "ma5"], name: "index_historical_quotes_on_base_stock_id_and_ma30", using: :btree
  add_index "historical_quotes", ["date"], name: "index_historical_quotes_on_date", using: :btree
  add_index "historical_quotes", ["symbol"], name: "index_historical_quotes_on_symbol", using: :btree

  create_table "historical_retries", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.string   "symbol",        limit: 255
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "historical_retries", ["base_stock_id"], name: "index_historical_retries_on_base_stock_id", using: :btree
  add_index "historical_retries", ["date"], name: "index_historical_retries_on_date", using: :btree
  add_index "historical_retries", ["symbol"], name: "index_historical_retries_on_symbol", using: :btree

  create_table "historical_stock_screeners", force: :cascade do |t|
    t.integer  "base_stock_id",       limit: 4,                                            null: false
    t.string   "symbol",              limit: 255
    t.boolean  "exchange_us",                                              default: false, null: false, comment: "美股市场"
    t.float    "score",               limit: 24,                           default: 0.0,   null: false, comment: "股票星级"
    t.boolean  "exchange_hk",                                              default: false, null: false, comment: "港股市场"
    t.boolean  "sector_bm",                                                default: false, null: false, comment: "基础材料"
    t.boolean  "sector_c",                                                 default: false, null: false, comment: "综合型大企业"
    t.boolean  "sector_cg",                                                default: false, null: false, comment: "消费品"
    t.boolean  "sector_f",                                                 default: false, null: false, comment: "金融"
    t.boolean  "sector_h",                                                 default: false, null: false, comment: "医疗"
    t.boolean  "sector_ig",                                                default: false, null: false, comment: "工业"
    t.boolean  "sector_s",                                                 default: false, null: false, comment: "服务业"
    t.boolean  "sector_t",                                                 default: false, null: false, comment: "高科技"
    t.boolean  "sector_u",                                                 default: false, null: false, comment: "公用事业"
    t.boolean  "sector_o",                                                 default: false, null: false, comment: "其他"
    t.boolean  "style_lp",                                                 default: false, null: false, comment: "价格低"
    t.boolean  "style_hg",                                                 default: false, null: false, comment: "高增长"
    t.boolean  "style_hq",                                                 default: false, null: false, comment: "高质量"
    t.boolean  "opinion_l",                                                default: false, null: false, comment: "华尔街看多"
    t.boolean  "opinion_s",                                                default: false, null: false, comment: "华尔街看空"
    t.boolean  "trend_g10",                                                default: false, null: false, comment: "当前价高于十日均线"
    t.boolean  "trend_l10",                                                default: false, null: false, comment: "当前价低于十日均线"
    t.boolean  "trend_h52",                                                default: false, null: false, comment: "当前价逼近52周最高"
    t.boolean  "trend_l52",                                                default: false, null: false, comment: "当前价逼近52周最低"
    t.boolean  "consideration_sc",                                         default: false, null: false, comment: "小市值（<十亿美金）"
    t.boolean  "consideration_bc",                                         default: false, null: false, comment: "大市值（>百亿美金）"
    t.boolean  "consideration_tg",                                         default: false, null: false, comment: "去年盈利且今年展望盈利"
    t.boolean  "consideration_bg",                                         default: false, null: false, comment: "盈利反转（去年亏损今年展望盈利）"
    t.boolean  "consideration_gg",                                         default: false, null: false, comment: "持续增长（营收及每股盈利展望高于去年）"
    t.boolean  "consideration_hg",                                         default: false, null: false, comment: "高增长（营收增长预期 > 16%）"
    t.boolean  "consideration_div",                                        default: false, null: false, comment: "有分红"
    t.boolean  "consideration_dgc",                                        default: false, null: false, comment: "现金及投资超过借贷的"
    t.decimal  "pe",                              precision: 18, scale: 3, default: 0.0,                comment: "市盈率"
    t.decimal  "pe_c",                            precision: 18, scale: 3, default: 0.0
    t.decimal  "lpg",                             precision: 18, scale: 3, default: 0.0,                comment: "长期盈利增长"
    t.decimal  "lpg_c",                           precision: 18, scale: 3, default: 0.0
    t.decimal  "cf",                              precision: 18, scale: 3, default: 0.0,                comment: "现金流"
    t.decimal  "cf_c",                            precision: 18, scale: 3, default: 0.0
    t.decimal  "gm",                              precision: 18, scale: 3, default: 0.0,                comment: "毛利润率"
    t.decimal  "gm_c",                            precision: 18, scale: 3, default: 0.0
    t.decimal  "wst",                             precision: 18, scale: 3, default: 0.0,                comment: "华尔街目标价格"
    t.decimal  "wst_c",                           precision: 18, scale: 3, default: 0.0
    t.decimal  "div",                             precision: 18, scale: 3, default: 0.0,                comment: "现金分红"
    t.decimal  "div_c",                           precision: 18, scale: 3, default: 0.0
    t.integer  "c1",                  limit: 4
    t.integer  "c2",                  limit: 4
    t.integer  "c3",                  limit: 4
    t.integer  "c4",                  limit: 4
    t.integer  "c5",                  limit: 4
    t.integer  "c6",                  limit: 4
    t.integer  "c7",                  limit: 4
    t.integer  "c8",                  limit: 4
    t.integer  "c9",                  limit: 4
    t.integer  "c10",                 limit: 4
    t.integer  "c11",                 limit: 4
    t.integer  "c12",                 limit: 4
    t.integer  "c13",                 limit: 4
    t.integer  "c14",                 limit: 4
    t.integer  "c15",                 limit: 4
    t.integer  "c16",                 limit: 4
    t.integer  "c17",                 limit: 4
    t.integer  "c18",                 limit: 4
    t.integer  "c19",                 limit: 4
    t.integer  "c20",                 limit: 4
    t.float    "pe_r",                limit: 24
    t.float    "lpg_r",               limit: 24
    t.float    "cf_r",                limit: 24
    t.float    "gm_r",                limit: 24
    t.float    "wst_r",               limit: 24
    t.float    "div_r",               limit: 24
    t.boolean  "country_usa",                                              default: false, null: false
    t.boolean  "country_can",                                              default: false, null: false
    t.boolean  "country_isr",                                              default: false, null: false
    t.boolean  "country_chn",                                              default: false, null: false
    t.boolean  "country_others",                                           default: false, null: false
    t.boolean  "country_hkg",                                              default: false,              comment: "香港"
    t.boolean  "capitalization_pe10",                                      default: false,              comment: "PE < 10"
    t.boolean  "capitalization_dy4",                                       default: false,              comment: "股息收益率 > 4%"
    t.boolean  "capitalization_clb",                                       default: false,              comment: "市值低于账面价值"
    t.boolean  "capitalization_cl1s",                                      default: false,              comment: "市值低于1倍销售额"
    t.boolean  "capitalization_cl7p",                                      default: false,              comment: "市值低于7倍经营利润"
    t.decimal  "wst_2",                           precision: 18, scale: 6, default: 0.0,                comment: "华尔街目标价格，wst为比例"
    t.decimal  "div_2",                           precision: 18, scale: 6, default: 0.0,                comment: "现金分红，div为比例"
    t.decimal  "change_rate",                     precision: 10, scale: 6, default: 0.0
    t.datetime "sync_time"
    t.datetime "created_at",                                                               null: false
    t.datetime "updated_at",                                                               null: false
  end

  create_table "history_basket_stocks", force: :cascade do |t|
    t.integer  "stock_id",   limit: 4
    t.integer  "basket_id",  limit: 4
    t.decimal  "weight",                 precision: 10, scale: 4
    t.string   "notes",      limit: 255
    t.string   "string",     limit: 255
    t.integer  "batch",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "history_basket_stocks", ["basket_id"], name: "index_history_basket_stocks_on_basket_id", using: :btree
  add_index "history_basket_stocks", ["batch"], name: "index_history_basket_stocks_on_batch", using: :btree
  add_index "history_basket_stocks", ["stock_id"], name: "index_history_basket_stocks_on_stock_id", using: :btree

  create_table "ib_fundamentals", force: :cascade do |t|
    t.string   "exchange",           limit: 255,                                             null: false
    t.string   "symbol",             limit: 255,                                             null: false
    t.text     "current_xml",        limit: 16777215
    t.text     "forecast_xml",       limit: 16777215
    t.string   "country_code",       limit: 255
    t.decimal  "target_price",                        precision: 16, scale: 2, default: 0.0
    t.decimal  "pe",                                  precision: 16, scale: 4, default: 0.0
    t.decimal  "peer_pe",                             precision: 16, scale: 4, default: 0.0
    t.decimal  "growth",                              precision: 16, scale: 4, default: 0.0
    t.decimal  "peer_growth",                         precision: 16, scale: 4, default: 0.0
    t.decimal  "forecast_growth",                     precision: 16, scale: 4, default: 0.0
    t.decimal  "net_profit",                          precision: 16,           default: 0
    t.decimal  "forecast_profit",                     precision: 16,           default: 0
    t.decimal  "revenue",                             precision: 16,           default: 0
    t.decimal  "forecast_revenue",                    precision: 16,           default: 0
    t.decimal  "dividend",                            precision: 16, scale: 2, default: 0.0
    t.decimal  "dividend_yield",                      precision: 16, scale: 4, default: 0.0
    t.decimal  "quick_ratio",                         precision: 16, scale: 4, default: 0.0
    t.decimal  "price_to_book",                       precision: 16, scale: 4, default: 0.0
    t.decimal  "price_to_sales",                      precision: 16, scale: 4, default: 0.0
    t.decimal  "price_to_cashflow",                   precision: 16, scale: 4, default: 0.0
    t.decimal  "ebitd_to_marketcap",                  precision: 16, scale: 4, default: 0.0
    t.decimal  "profit_margin",                       precision: 16, scale: 4, default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "price",                               precision: 14, scale: 4
    t.decimal  "marketcap",                           precision: 14, scale: 2
    t.decimal  "ebitd",                               precision: 14, scale: 2
    t.decimal  "cashflow",                            precision: 14, scale: 4
  end

  add_index "ib_fundamentals", ["exchange"], name: "index_ib_fundamentals_on_exchange", using: :btree
  add_index "ib_fundamentals", ["symbol", "exchange"], name: "index_ib_fundamentals_on_symbol_and_exchange", unique: true, using: :btree
  add_index "ib_fundamentals", ["symbol"], name: "index_ib_fundamentals_on_symbol", using: :btree

  create_table "ib_order_sequences", force: :cascade do |t|
    t.integer  "ib_order_id", limit: 4
    t.integer  "sequence",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ib_positions", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "base_stock_id",      limit: 4
    t.string   "symbol",             limit: 255
    t.integer  "contract_id",        limit: 4
    t.string   "account_name",       limit: 255
    t.decimal  "position",                       precision: 16, scale: 2
    t.string   "exchange",           limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.integer  "trading_account_id", limit: 4
  end

  add_index "ib_positions", ["trading_account_id", "base_stock_id"], name: "index_ib_positions_on_trading_account_id_and_base_stock_id", using: :btree

  create_table "intraday_quotes", force: :cascade do |t|
    t.integer  "base_id",               limit: 4
    t.string   "symbol",                limit: 30
    t.string   "market",                limit: 10
    t.datetime "trade_time"
    t.integer  "volume",                limit: 4
    t.decimal  "last_trade_price_only",             precision: 9, scale: 3
    t.string   "changein_percent",      limit: 255
    t.decimal  "change",                            precision: 8, scale: 3
    t.decimal  "previous_close",                    precision: 9, scale: 3
    t.datetime "expired_at"
    t.datetime "created_at"
    t.date     "local_date"
  end

  add_index "intraday_quotes", ["base_id", "trade_time"], name: "index_intraday_quotes_on_base_id_and_trade_time", unique: true, using: :btree
  add_index "intraday_quotes", ["expired_at"], name: "index_intraday_quotes_on_expired_at", using: :btree
  add_index "intraday_quotes", ["trade_time"], name: "index_intraday_quotes_on_trade_time", using: :btree

  create_table "invitation_codes", force: :cascade do |t|
    t.string   "code",             limit: 255
    t.boolean  "used",                         default: false
    t.integer  "lead_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",          limit: 4
    t.string   "type",             limit: 255
    t.integer  "invitation_limit", limit: 4
    t.integer  "super_user_id",    limit: 4
  end

  add_index "invitation_codes", ["code"], name: "index_invitation_codes_on_code", using: :btree
  add_index "invitation_codes", ["lead_id"], name: "index_invitation_codes_on_lead_id", using: :btree
  add_index "invitation_codes", ["super_user_id"], name: "index_invitation_codes_on_super_user_id", using: :btree
  add_index "invitation_codes", ["type"], name: "index_invitation_codes_on_type", using: :btree

  create_table "invitations", force: :cascade do |t|
    t.integer "sender_id", limit: 4
    t.string  "token",     limit: 255
    t.boolean "used",                  default: false
  end

  add_index "invitations", ["sender_id"], name: "index_invitations_on_sender_id", using: :btree
  add_index "invitations", ["token"], name: "index_invitations_on_token", unique: true, using: :btree

  create_table "jy_components", force: :cascade do |t|
    t.datetime "begin_date"
    t.string   "l_one_name", limit: 50
    t.integer  "l_one_code", limit: 4
    t.string   "l_two_name", limit: 50
    t.string   "l_two_code", limit: 50
    t.integer  "flag",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jy_components", ["l_two_code"], name: "index_jy_components_on_l_two_code", unique: true, using: :btree

  create_table "jy_industries", force: :cascade do |t|
    t.string   "name",       limit: 100
    t.integer  "code",       limit: 4
    t.integer  "level",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jy_industries", ["code"], name: "index_jy_industries_on_code", unique: true, using: :btree
  add_index "jy_industries", ["name"], name: "index_jy_industries_on_name", using: :btree

  create_table "jy_split_logs", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.date     "date"
    t.decimal  "new_price",               precision: 12, scale: 3
    t.decimal  "old_price",               precision: 12, scale: 3
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jy_split_logs", ["base_stock_id", "date"], name: "index_jy_split_logs_on_base_stock_id_and_date", using: :btree

  create_table "kline_ma_caches", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.string   "category",      limit: 255
    t.date     "date"
    t.string   "ma5",           limit: 255
    t.string   "ma10",          limit: 255
    t.string   "ma20",          limit: 255
    t.string   "ma30",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kline_ma_caches", ["base_stock_id", "category"], name: "index_kline_ma_caches_on_base_stock_id_and_category", unique: true, using: :btree

  create_table "klines", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.string   "symbol",        limit: 255
    t.decimal  "open",                      precision: 16, scale: 3
    t.decimal  "close",                     precision: 16, scale: 3
    t.decimal  "high",                      precision: 16, scale: 3
    t.decimal  "low",                       precision: 16, scale: 3
    t.integer  "volume",        limit: 8
    t.integer  "category",      limit: 4
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "ma5",                       precision: 10, scale: 3
  end

  add_index "klines", ["base_stock_id", "category", "start_date"], name: "index_klines_on_base_stock_id_and_category_and_start_date", unique: true, using: :btree

  create_table "landings", force: :cascade do |t|
    t.string   "email",      limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "request_ip", limit: 255
  end

  add_index "landings", ["email"], name: "index_landings_on_email", using: :btree

  create_table "leads", force: :cascade do |t|
    t.string   "username",        limit: 255
    t.string   "gender",          limit: 255
    t.string   "company",         limit: 255
    t.string   "mobile",          limit: 255
    t.string   "email",           limit: 255
    t.string   "weixin",          limit: 255
    t.string   "qq",              limit: 255
    t.string   "address",         limit: 255
    t.integer  "invite_user_id",  limit: 4
    t.string   "source",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",         limit: 4
    t.boolean  "invited",                     default: false
    t.string   "invite_username", limit: 255
    t.integer  "landing_id",      limit: 4
    t.datetime "send_at"
  end

  add_index "leads", ["email"], name: "index_leads_on_email", using: :btree
  add_index "leads", ["invite_user_id"], name: "index_leads_on_invite_user_id", using: :btree

  create_table "likes", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "feed_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "likeable_id",   limit: 4
    t.string   "likeable_type", limit: 16
  end

  add_index "likes", ["feed_id"], name: "index_likes_on_feed_id", using: :btree
  add_index "likes", ["likeable_id", "likeable_type"], name: "index_likes_on_likeable_id_and_likeable_type", using: :btree
  add_index "likes", ["user_id"], name: "index_likes_on_user_id", using: :btree

  create_table "majia_users", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "email",       limit: 255
    t.string   "password",    limit: 255
    t.string   "username",    limit: 255
    t.boolean  "gender"
    t.integer  "province",    limit: 4
    t.string   "city",        limit: 50
    t.string   "headline",    limit: 255
    t.string   "orientation", limit: 255
    t.string   "concern",     limit: 255
    t.string   "duration",    limit: 255
    t.boolean  "status",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "majia_users", ["email"], name: "index_majia_users_on_email", using: :btree
  add_index "majia_users", ["user_id"], name: "index_majia_users_on_user_id", using: :btree

  create_table "message_talks", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "subscriber_id", limit: 4
    t.integer  "recent_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_talks", ["subscriber_id"], name: "index_message_talks_on_subscriber_id", using: :btree
  add_index "message_talks", ["user_id"], name: "index_message_talks_on_user_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.integer  "sender_id",          limit: 4
    t.integer  "receiver_id",        limit: 4
    t.boolean  "read",                             default: false
    t.text     "content",            limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_talk_id",       limit: 4
    t.integer  "subscriber_talk_id", limit: 4
  end

  add_index "messages", ["receiver_id"], name: "index_messages_on_receiver_id", using: :btree
  add_index "messages", ["sender_id"], name: "index_messages_on_sender_id", using: :btree
  add_index "messages", ["subscriber_talk_id"], name: "index_messages_on_subscriber_talk_id", using: :btree
  add_index "messages", ["user_talk_id"], name: "index_messages_on_user_talk_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.integer  "mentionable_id",    limit: 4
    t.string   "mentionable_type",  limit: 191
    t.boolean  "read",                            default: false
    t.string   "type",              limit: 32
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content",           limit: 65535
    t.integer  "triggered_user_id", limit: 4
    t.integer  "originable_id",     limit: 4
    t.string   "originable_type",   limit: 191
    t.integer  "targetable_id",     limit: 4
    t.string   "targetable_type",   limit: 191
    t.string   "title",             limit: 255
  end

  add_index "notifications", ["mentionable_id", "mentionable_type"], name: "index_notifications_on_mentionable_id_and_mentionable_type", using: :btree
  add_index "notifications", ["originable_id", "originable_type"], name: "index_notifications_on_originable_id_and_originable_type", using: :btree
  add_index "notifications", ["read"], name: "index_notifications_on_read", using: :btree
  add_index "notifications", ["targetable_id", "targetable_type"], name: "index_notifications_on_targetable_id_and_targetable_type", using: :btree
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "opinions", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.integer  "opinionable_id",   limit: 4
    t.string   "opinionable_type", limit: 16
    t.integer  "opinion",          limit: 4
    t.datetime "post_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "opinions", ["opinionable_type", "opinionable_id", "opinion"], name: "idx_opinions_of_opinion_opinionable", using: :btree
  add_index "opinions", ["opinionable_type", "opinionable_id"], name: "index_opinions_on_opinionable_type_and_opinionable_id", using: :btree
  add_index "opinions", ["user_id"], name: "index_opinions_on_user_id", using: :btree

  create_table "order_details", force: :cascade do |t|
    t.integer  "order_id",           limit: 4
    t.string   "instance_id",        limit: 50
    t.integer  "base_stock_id",      limit: 4
    t.integer  "user_id",            limit: 4
    t.integer  "basket_id",          limit: 4
    t.decimal  "est_shares",                     precision: 16, scale: 2
    t.decimal  "real_shares",                    precision: 16, scale: 2
    t.decimal  "est_cost",                       precision: 16, scale: 3
    t.decimal  "real_cost",                      precision: 16, scale: 3
    t.string   "status",             limit: 255
    t.string   "symbol",             limit: 255
    t.string   "ib_order_id",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "trade_type",         limit: 255
    t.datetime "trade_time"
    t.string   "order_type",         limit: 255
    t.decimal  "limit_price",                    precision: 16, scale: 2
    t.string   "updated_by",         limit: 255
    t.decimal  "commission",                     precision: 16, scale: 2,  default: 0.0
    t.boolean  "background",                                               default: false
    t.decimal  "average_cost",                   precision: 16, scale: 10, default: 0.0
    t.string   "market",             limit: 255
    t.string   "currency",           limit: 255
    t.string   "cash_id",            limit: 255
    t.integer  "trading_account_id", limit: 4
    t.string   "rt_order_id",        limit: 255
    t.string   "result",             limit: 100
  end

  add_index "order_details", ["base_stock_id"], name: "index_order_details_on_base_stock_id", using: :btree
  add_index "order_details", ["basket_id"], name: "index_order_details_on_basket_id", using: :btree
  add_index "order_details", ["cash_id"], name: "index_order_details_on_cash_id", using: :btree
  add_index "order_details", ["ib_order_id"], name: "index_order_details_on_ib_order_id", using: :btree
  add_index "order_details", ["instance_id", "base_stock_id"], name: "index_order_details_on_instance_id_and_base_stock_id", using: :btree
  add_index "order_details", ["instance_id", "symbol"], name: "index_order_details_on_instance_id_and_symbol", using: :btree
  add_index "order_details", ["instance_id"], name: "index_order_details_on_instance_id", using: :btree
  add_index "order_details", ["order_id"], name: "index_order_details_on_order_id", using: :btree
  add_index "order_details", ["rt_order_id"], name: "index_order_details_on_rt_order_id", unique: true, using: :btree
  add_index "order_details", ["status"], name: "index_order_details_on_status", using: :btree
  add_index "order_details", ["symbol"], name: "index_order_details_on_symbol", using: :btree
  add_index "order_details", ["trading_account_id", "instance_id", "base_stock_id", "trade_time"], name: "stock_profit_index", using: :btree
  add_index "order_details", ["trading_account_id", "instance_id", "trade_time"], name: "basket_profit_index", using: :btree
  add_index "order_details", ["trading_account_id"], name: "index_order_details_on_trading_account_id", using: :btree
  add_index "order_details", ["user_id", "trading_account_id", "trade_time"], name: "combine_indexes_for_order_details", using: :btree
  add_index "order_details", ["user_id"], name: "index_order_details_on_user_id", using: :btree

  create_table "order_errors", force: :cascade do |t|
    t.integer  "order_id",    limit: 4
    t.integer  "ib_order_id", limit: 4
    t.string   "symbol",      limit: 255
    t.string   "code",        limit: 255
    t.string   "message",     limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "order_errs", force: :cascade do |t|
    t.integer  "order_id",    limit: 4
    t.string   "ib_order_id", limit: 255
    t.string   "symbol",      limit: 255
    t.string   "code",        limit: 255
    t.text     "message",     limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "order_logs", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "order_id",           limit: 4
    t.string   "ib_order_id",        limit: 255
    t.string   "instance_id",        limit: 255
    t.integer  "base_stock_id",      limit: 4
    t.integer  "sequence",           limit: 4
    t.integer  "filled",             limit: 4
    t.decimal  "cost",                           precision: 16, scale: 3, default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "remaining",          limit: 4
    t.integer  "total_filled",       limit: 4
    t.decimal  "avg_price",                      precision: 16, scale: 2, default: 0.0
    t.string   "trading_account_id", limit: 255
  end

  create_table "order_stock_shares", force: :cascade do |t|
    t.string   "instance_id",   limit: 255
    t.integer  "order_id",      limit: 4
    t.integer  "base_stock_id", limit: 4
    t.integer  "shares",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "order_stock_shares", ["base_stock_id"], name: "index_order_stock_shares_on_base_stock_id", using: :btree
  add_index "order_stock_shares", ["instance_id"], name: "index_order_stock_shares_on_instance_id", using: :btree
  add_index "order_stock_shares", ["order_id"], name: "index_order_stock_shares_on_order_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.string   "instance_id",                  limit: 50
    t.integer  "user_id",                      limit: 4
    t.integer  "basket_id",                    limit: 4
    t.decimal  "basket_mount",                             precision: 16, scale: 2
    t.decimal  "est_cost",                                 precision: 16, scale: 2
    t.decimal  "real_cost",                                precision: 16, scale: 2
    t.integer  "category",                     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                       limit: 255
    t.integer  "order_details_complete_count", limit: 4,                            default: 0
    t.string   "type",                         limit: 255
    t.datetime "expiry"
    t.string   "updated_by",                   limit: 255
    t.boolean  "background"
    t.decimal  "commission",                               precision: 16, scale: 2, default: 0.0
    t.string   "exchange",                     limit: 255
    t.string   "product_type",                 limit: 255
    t.string   "market",                       limit: 255
    t.string   "sn",                           limit: 255
    t.string   "source",                       limit: 255
    t.boolean  "gtd"
    t.integer  "trading_account_id",           limit: 4
    t.string   "cash_id",                      limit: 255
  end

  add_index "orders", ["basket_id"], name: "index_orders_on_basket_id", using: :btree
  add_index "orders", ["basket_mount"], name: "index_orders_on_basket_mount", using: :btree
  add_index "orders", ["instance_id"], name: "index_orders_on_instance_id", using: :btree
  add_index "orders", ["source"], name: "index_orders_on_source", using: :btree
  add_index "orders", ["trading_account_id"], name: "index_orders_on_trading_account_id", using: :btree
  add_index "orders", ["user_id"], name: "index_orders_on_user_id", using: :btree

  create_table "p2p_strategies", force: :cascade do |t|
    t.string   "base_type",        limit: 255
    t.integer  "staffer_id",       limit: 4
    t.integer  "mentionable_id",   limit: 4
    t.string   "mentionable_type", limit: 255
    t.string   "change_type",      limit: 255
    t.decimal  "weight",                       precision: 13, scale: 4, default: 1.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "url",        limit: 255
    t.integer  "father_id",  limit: 4,   default: 0
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "staffer_id", limit: 4,   default: 0
  end

  create_table "phone_book_items", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.string   "name",          limit: 255
    t.integer  "phone_book_id", limit: 4
    t.string   "item_type",     limit: 255, default: "mobile", null: false
    t.string   "item",          limit: 255
    t.integer  "caishuo_id",    limit: 4
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  create_table "phone_books", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.integer  "items_count", limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "players", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "contest_id",         limit: 4
    t.string   "original_money",     limit: 255
    t.integer  "status",             limit: 4
    t.integer  "trading_account_id", limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.float    "ret",                limit: 24
  end

  create_table "portfolio_archives", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "base_stock_id",      limit: 4
    t.date     "archive_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",           limit: 4
    t.string   "currency",           limit: 255
    t.string   "symbol",             limit: 255
    t.integer  "contract_id",        limit: 4
    t.string   "account_name",       limit: 255
    t.string   "updated_by",         limit: 255
    t.decimal  "market_price",                   precision: 16, scale: 2
    t.decimal  "market_value",                   precision: 25, scale: 10, default: 0.0
    t.decimal  "average_cost",                   precision: 16, scale: 2
    t.decimal  "unrealized_pnl",                 precision: 25, scale: 10, default: 0.0
    t.decimal  "realized_pnl",                   precision: 25, scale: 10, default: 0.0
    t.integer  "trading_account_id", limit: 4
  end

  add_index "portfolio_archives", ["trading_account_id"], name: "index_portfolio_archives_on_trading_account_id", using: :btree
  add_index "portfolio_archives", ["user_id", "base_stock_id", "archive_date"], name: "unique_index_portfolio_archives", unique: true, using: :btree

  create_table "portfolios", force: :cascade do |t|
    t.integer  "base_stock_id",      limit: 4
    t.integer  "user_id",            limit: 4
    t.integer  "position",           limit: 4
    t.string   "currency",           limit: 255
    t.string   "symbol",             limit: 255
    t.integer  "contract_id",        limit: 4
    t.string   "account_name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "updated_by",         limit: 255
    t.decimal  "market_price",                   precision: 16, scale: 10
    t.decimal  "market_value",                   precision: 25, scale: 10, default: 0.0
    t.decimal  "average_cost",                   precision: 16, scale: 10
    t.decimal  "unrealized_pnl",                 precision: 25, scale: 10, default: 0.0
    t.decimal  "realized_pnl",                   precision: 25, scale: 10, default: 0.0
    t.integer  "trading_account_id", limit: 4
  end

  add_index "portfolios", ["user_id", "base_stock_id"], name: "index_portfolios_on_user_id_and_base_stock_id", using: :btree
  add_index "portfolios", ["user_id"], name: "index_portfolios_on_user_id", using: :btree

  create_table "position_archives", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "instance_id",        limit: 255
    t.integer  "base_stock_id",      limit: 4
    t.date     "archive_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "shares",                         precision: 16, scale: 2, default: 0.0
    t.integer  "basket_id",          limit: 4
    t.decimal  "basket_mount",                   precision: 16, scale: 2
    t.decimal  "average_cost",                   precision: 16, scale: 2, default: 0.0
    t.integer  "pending_shares",     limit: 4
    t.string   "updated_by",         limit: 255
    t.string   "market",             limit: 10
    t.string   "currency",           limit: 10
    t.decimal  "close_price",                    precision: 16, scale: 3
    t.integer  "trading_account_id", limit: 4
    t.string   "cash_id",            limit: 255
    t.float    "adjusted_shares",    limit: 24
  end

  add_index "position_archives", ["archive_date"], name: "index_position_archives_on_archive_date", using: :btree
  add_index "position_archives", ["cash_id"], name: "index_position_archives_on_cash_id", using: :btree
  add_index "position_archives", ["instance_id"], name: "index_position_archives_on_instance_id", using: :btree
  add_index "position_archives", ["trading_account_id"], name: "index_position_archives_on_trading_account_id", using: :btree
  add_index "position_archives", ["user_id", "trading_account_id", "instance_id", "base_stock_id", "archive_date"], name: "unique_index_position_archives", unique: true, using: :btree
  add_index "position_archives", ["user_id"], name: "index_position_archives_on_user_id", using: :btree

  create_table "positions", force: :cascade do |t|
    t.string   "instance_id",        limit: 50
    t.integer  "base_stock_id",      limit: 4
    t.integer  "basket_id",          limit: 4
    t.integer  "user_id",            limit: 4
    t.decimal  "shares",                         precision: 16, scale: 2
    t.decimal  "basket_mount",                   precision: 16, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "average_cost",                   precision: 16, scale: 10, default: 0.0
    t.integer  "pending_shares",     limit: 4
    t.string   "updated_by",         limit: 255
    t.string   "market",             limit: 255
    t.string   "currency",           limit: 255
    t.string   "cash_id",            limit: 255
    t.integer  "trading_account_id", limit: 4
    t.decimal  "buy_frozen",                     precision: 16, scale: 2,  default: 0.0
    t.decimal  "pnl",                            precision: 16, scale: 2
    t.decimal  "today_pnl",                      precision: 16, scale: 2
    t.decimal  "closed_cost",                    precision: 16, scale: 2,                comment: "平仓时成本价"
  end

  add_index "positions", ["base_stock_id"], name: "index_positions_on_base_stock_id", using: :btree
  add_index "positions", ["basket_id"], name: "index_positions_on_basket_id", using: :btree
  add_index "positions", ["cash_id"], name: "index_positions_on_cash_id", using: :btree
  add_index "positions", ["instance_id", "base_stock_id", "trading_account_id"], name: "instance_stock_account_unique_index", unique: true, using: :btree
  add_index "positions", ["instance_id"], name: "index_positions_on_instance_id", using: :btree
  add_index "positions", ["trading_account_id"], name: "index_positions_on_trading_account_id", using: :btree
  add_index "positions", ["user_id"], name: "index_positions_on_user_id", using: :btree

  create_table "pre_contestants", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "contest_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pre_contestants", ["user_id", "contest_id"], name: "index_pre_contestants_on_user_id_and_contest_id", using: :btree

  create_table "production_stocks", force: :cascade do |t|
    t.integer "symbol", limit: 4
  end

  create_table "profiles", force: :cascade do |t|
    t.string   "orientations", limit: 255
    t.string   "concerns",     limit: 255
    t.string   "professions",  limit: 255
    t.integer  "duration",     limit: 4
    t.integer  "user_id",      limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.text     "intro",        limit: 65535
  end

  create_table "pt_applications", force: :cascade do |t|
    t.string   "user_id",      limit: 255
    t.integer  "status",       limit: 4,     default: 0
    t.string   "mobile",       limit: 255
    t.integer  "q1",           limit: 4
    t.integer  "q2",           limit: 4
    t.integer  "q3",           limit: 4
    t.string   "q4",           limit: 255
    t.text     "q5",           limit: 65535
    t.text     "q6",           limit: 65535
    t.text     "q7",           limit: 65535
    t.text     "q8",           limit: 65535
    t.text     "q9",           limit: 65535
    t.string   "name",         limit: 255
    t.string   "id_no",        limit: 255
    t.string   "industry",     limit: 255
    t.string   "com_name",     limit: 255
    t.string   "bank_name",    limit: 255
    t.string   "card_no",      limit: 255
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "noticed",                    default: false
    t.integer  "current_step", limit: 4,     default: 1
  end

  create_table "push_logs", force: :cascade do |t|
    t.string   "push_type",        limit: 30
    t.string   "push_key",         limit: 30
    t.integer  "staffer_id",       limit: 4
    t.text     "content",          limit: 65535
    t.text     "result",           limit: 65535
    t.integer  "status",           limit: 4,     default: 0
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "mentionable_type", limit: 255
    t.string   "mentionable_id",   limit: 255
  end

  create_table "quote_changes", force: :cascade do |t|
    t.string   "symbol",     limit: 255
    t.decimal  "adj_close",              precision: 16, scale: 3
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sign",       limit: 255
  end

  add_index "quote_changes", ["symbol", "date"], name: "index_quote_changes_on_symbol_and_date", using: :btree
  add_index "quote_changes", ["symbol"], name: "index_quote_changes_on_symbol", using: :btree

  create_table "quote_resync_logs", force: :cascade do |t|
    t.string   "symbol",        limit: 255,                                          null: false
    t.integer  "category",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base_id",       limit: 4
    t.decimal  "old_adj_close",             precision: 16, scale: 3
    t.decimal  "new_adj_close",             precision: 16, scale: 3
    t.boolean  "kline",                                              default: false
  end

  add_index "quote_resync_logs", ["base_id", "kline"], name: "index_quote_resync_logs_on_base_id_and_kline", using: :btree

  create_table "quotes", force: :cascade do |t|
    t.string   "symbol",     limit: 255,                           null: false
    t.date     "date"
    t.decimal  "open",                   precision: 16, scale: 3
    t.decimal  "high",                   precision: 16, scale: 3
    t.decimal  "low",                    precision: 16, scale: 3
    t.decimal  "close",                  precision: 16, scale: 3
    t.integer  "volume",     limit: 8
    t.decimal  "adj_close",              precision: 16, scale: 4
    t.decimal  "index",                  precision: 30, scale: 13
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base_id",    limit: 4
  end

  add_index "quotes", ["base_id", "date"], name: "index_quotes_on_base_id_and_date", unique: true, using: :btree
  add_index "quotes", ["base_id"], name: "index_quotes_on_base_id", using: :btree
  add_index "quotes", ["date"], name: "index_quotes_on_date", using: :btree

  create_table "recommends", force: :cascade do |t|
    t.integer  "staffer_id",   limit: 4
    t.string   "status",       limit: 255
    t.string   "original_url", limit: 255
    t.string   "current_url",  limit: 255
    t.string   "verifiers",    limit: 255
    t.string   "title",        limit: 255
    t.text     "content",      limit: 65535
    t.datetime "published_at"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "source",       limit: 255
    t.string   "category",     limit: 255
    t.string   "news_id",      limit: 255
    t.string   "category_id",  limit: 255
    t.text     "pic_urls",     limit: 65535
  end

  create_table "reconcile_request_lists", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "broker_user_id",     limit: 255
    t.integer  "count",              limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "symbol",             limit: 65535
    t.string   "updated_by",         limit: 255
    t.integer  "trading_account_id", limit: 4
    t.string   "type",               limit: 255
  end

  create_table "retry_orders", force: :cascade do |t|
    t.integer  "order_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.integer  "role_id",       limit: 4
    t.integer  "permission_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "rt_logs", force: :cascade do |t|
    t.string   "message",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rt_logs", ["message"], name: "index_rt_logs_on_message", using: :btree

  create_table "rt_quotes", force: :cascade do |t|
    t.integer  "base_stock_id",                      limit: 4
    t.string   "symbol",                             limit: 30
    t.string   "market",                             limit: 10
    t.decimal  "previous_close",                                precision: 10, scale: 3
    t.decimal  "last",                                          precision: 10, scale: 3
    t.decimal  "high52_weeks",                                  precision: 10, scale: 3
    t.decimal  "low52_weeks",                                   precision: 10, scale: 3
    t.decimal  "open",                                          precision: 10, scale: 3
    t.decimal  "high",                                          precision: 10, scale: 3
    t.decimal  "low",                                           precision: 10, scale: 3
    t.decimal  "ask",                                           precision: 10, scale: 3
    t.decimal  "bid",                                           precision: 10, scale: 3
    t.string   "change_from_previous_close",         limit: 10
    t.string   "percent_change_from_previous_close", limit: 10
    t.string   "currency",                           limit: 10
    t.integer  "volume",                             limit: 4
    t.datetime "trade_time"
    t.datetime "expired_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "local_date"
  end

  add_index "rt_quotes", ["base_stock_id", "trade_time"], name: "index_rt_quotes_on_base_stock_id_and_trade_time", unique: true, using: :btree
  add_index "rt_quotes", ["expired_at"], name: "index_rt_quotes_on_expired_at", using: :btree
  add_index "rt_quotes", ["symbol"], name: "index_rt_quotes_on_symbol", using: :btree
  add_index "rt_quotes", ["trade_time"], name: "index_rt_quotes_on_trade_time", using: :btree

  create_table "rt_stocks", force: :cascade do |t|
    t.integer  "base_id",               limit: 4
    t.string   "symbol",                limit: 255
    t.integer  "average_daily_volume",  limit: 8
    t.decimal  "ask_realtime",                      precision: 16, scale: 3
    t.decimal  "bid_realtime",                      precision: 16, scale: 3
    t.string   "change",                limit: 255
    t.decimal  "dividend_share",                    precision: 16, scale: 3
    t.decimal  "earnings_share",                    precision: 16, scale: 3
    t.decimal  "days_low",                          precision: 16, scale: 3
    t.decimal  "days_high",                         precision: 16, scale: 3
    t.decimal  "year_low",                          precision: 16, scale: 3
    t.decimal  "year_high",                         precision: 16, scale: 3
    t.string   "market_capitalization", limit: 255
    t.decimal  "last_trade_price_only",             precision: 16, scale: 3
    t.string   "days_range",            limit: 255
    t.string   "name",                  limit: 255
    t.decimal  "open",                              precision: 16, scale: 3
    t.decimal  "previous_close",                    precision: 16, scale: 3
    t.string   "changein_percent",      limit: 255
    t.decimal  "pe_ratio",                          precision: 16, scale: 3
    t.string   "last_trade_time",       limit: 255
    t.integer  "volume",                limit: 8
    t.string   "year_range",            limit: 255
    t.string   "stock_exchange",        limit: 255
    t.decimal  "high",                              precision: 16, scale: 3
    t.decimal  "low",                               precision: 16, scale: 3
    t.string   "status",                limit: 255,                          default: "Trading"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency",              limit: 255
    t.date     "date"
  end

  add_index "rt_stocks", ["base_id", "date"], name: "index_rt_stocks_on_base_id_and_date", unique: true, using: :btree

  create_table "sectors", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "c_name",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shipan_images", force: :cascade do |t|
    t.string   "key",        limit: 255
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "sms_contents", force: :cascade do |t|
    t.string   "phone",       limit: 255
    t.text     "msg_content", limit: 65535
    t.string   "sp_number",   limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "sms_reports", force: :cascade do |t|
    t.string   "plat_form",         limit: 255
    t.string   "f_unikey",          limit: 255
    t.string   "f_org_addr",        limit: 255
    t.string   "f_dest_addr",       limit: 255
    t.string   "f_submit_time",     limit: 255
    t.string   "f_fee_terminal",    limit: 255
    t.string   "f_service_u_p_i_d", limit: 255
    t.string   "f_report_code",     limit: 255
    t.string   "f_link_i_d",        limit: 255
    t.string   "f_ack_status",      limit: 255
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "sources", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "url",        limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "code",       limit: 255
  end

  create_table "staffers", force: :cascade do |t|
    t.string   "username",             limit: 255,                 null: false
    t.string   "encrypted_password",   limit: 255,                 null: false
    t.string   "email",                limit: 255
    t.string   "fullname",             limit: 255
    t.boolean  "admin",                            default: false
    t.integer  "role_id",              limit: 4
    t.integer  "sign_in_count",        limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",   limit: 255
    t.string   "last_sign_in_ip",      limit: 255
    t.boolean  "deleted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_token",   limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",    limit: 255
  end

  add_index "staffers", ["role_id"], name: "index_staffers_on_role_id", using: :btree
  add_index "staffers", ["username"], name: "index_staffers_on_username", unique: true, using: :btree

  create_table "static_contents", force: :cascade do |t|
    t.string   "sourceable_type", limit: 30
    t.string   "sourceable_id",   limit: 30
    t.integer  "follows_count",   limit: 4,     default: 0
    t.string   "title",           limit: 255
    t.text     "data",            limit: 65535
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "comments_count",  limit: 4,     default: 0
  end

  add_index "static_contents", ["sourceable_type", "sourceable_id"], name: "index_static_contents_on_sourceable_type_and_sourceable_id", using: :btree

  create_table "stock_accounts", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "trading_account_id", limit: 4
    t.string   "broker_no",          limit: 50
    t.string   "market",             limit: 10
    t.string   "account_code",       limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stock_accounts", ["trading_account_id", "market"], name: "index_stock_accounts_on_trading_account_id_and_market", using: :btree

  create_table "stock_adjusting_factors", force: :cascade do |t|
    t.integer  "base_stock_id",          limit: 4
    t.integer  "inner_code",             limit: 4
    t.date     "ex_divi_date"
    t.decimal  "adjusting_factor",                 precision: 12, scale: 5
    t.decimal  "adjusting_const",                  precision: 12, scale: 5
    t.decimal  "ratio_adjusting_factor",           precision: 12, scale: 5
    t.datetime "xgrq"
    t.decimal  "accu_cash_divi",                   precision: 12, scale: 5
    t.decimal  "accu_bonus_share_ratio",           precision: 12, scale: 5
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stock_adjusting_factors", ["base_stock_id", "ex_divi_date"], name: "index_stock_adjusting_factors_on_base_stock_id_and_ex_divi_date", unique: true, using: :btree

  create_table "stock_changes", force: :cascade do |t|
    t.integer  "from_id",     limit: 4
    t.integer  "to_id",       limit: 4
    t.string   "from_symbol", limit: 255
    t.string   "to_symbol",   limit: 255
    t.date     "date"
    t.string   "factor",      limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "stock_components", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.integer  "inner_code",    limit: 4
    t.integer  "cs_code",       limit: 4
    t.string   "name",          limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stock_components", ["base_stock_id", "name"], name: "index_stock_components_on_base_stock_id_and_name", unique: true, using: :btree

  create_table "stock_dividends", force: :cascade do |t|
    t.string   "symbol",        limit: 255
    t.string   "amount",        limit: 255
    t.date     "ex_div_date"
    t.date     "record_date"
    t.date     "payable_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base_stock_id", limit: 4
  end

  create_table "stock_industries", force: :cascade do |t|
    t.integer  "base_stock_id",        limit: 4
    t.string   "first_industry_code",  limit: 100
    t.string   "first_industry_name",  limit: 255
    t.string   "second_industry_code", limit: 100
    t.string   "second_industry_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "cancel_date"
    t.integer  "sector_code",          limit: 4
    t.integer  "industry",             limit: 4
    t.string   "third_industry_code",  limit: 20
    t.string   "third_industry_name",  limit: 100
    t.integer  "if_performed",         limit: 4
  end

  add_index "stock_industries", ["base_stock_id", "industry"], name: "index_stock_industries_on_base_stock_id_and_industry", unique: true, using: :btree
  add_index "stock_industries", ["first_industry_code"], name: "index_stock_industries_on_first_industry_code", using: :btree
  add_index "stock_industries", ["industry"], name: "index_stock_industries_on_industry", using: :btree
  add_index "stock_industries", ["second_industry_code"], name: "index_stock_industries_on_second_industry_code", using: :btree
  add_index "stock_industries", ["sector_code"], name: "index_stock_industries_on_sector_code", using: :btree

  create_table "stock_infos", force: :cascade do |t|
    t.text     "description",     limit: 65535
    t.string   "site",            limit: 255
    t.string   "telephone",       limit: 255
    t.text     "profession",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "base_stock_id",   limit: 4
    t.string   "company_address", limit: 255
    t.string   "symbol",          limit: 255
  end

  add_index "stock_infos", ["base_stock_id"], name: "index_stock_infos_on_base_stock_id", using: :btree

  create_table "stock_reminders", force: :cascade do |t|
    t.integer "user_id",        limit: 4,   null: false
    t.integer "stock_id",       limit: 4,   null: false
    t.string  "reminder_type",  limit: 255, null: false
    t.float   "reminder_value", limit: 24
  end

  add_index "stock_reminders", ["user_id", "stock_id", "reminder_type"], name: "index_stock_reminders_on_user_id_and_stock_id_and_reminder_type", unique: true, using: :btree
  add_index "stock_reminders", ["user_id"], name: "index_stock_reminders_on_user_id", using: :btree

  create_table "stock_screeners", force: :cascade do |t|
    t.integer "base_stock_id",       limit: 4,                                            null: false
    t.string  "symbol",              limit: 255
    t.boolean "exchange_us",                                              default: false, null: false, comment: "美股市场"
    t.float   "score",               limit: 24,                           default: 0.0,   null: false, comment: "股票星级"
    t.boolean "exchange_hk",                                              default: false, null: false, comment: "港股市场"
    t.boolean "sector_bm",                                                default: false, null: false, comment: "基础材料"
    t.boolean "sector_c",                                                 default: false, null: false, comment: "综合型大企业"
    t.boolean "sector_cg",                                                default: false, null: false, comment: "消费品"
    t.boolean "sector_f",                                                 default: false, null: false, comment: "金融"
    t.boolean "sector_h",                                                 default: false, null: false, comment: "医疗"
    t.boolean "sector_ig",                                                default: false, null: false, comment: "工业"
    t.boolean "sector_s",                                                 default: false, null: false, comment: "服务业"
    t.boolean "sector_t",                                                 default: false, null: false, comment: "高科技"
    t.boolean "sector_u",                                                 default: false, null: false, comment: "公用事业"
    t.boolean "sector_o",                                                 default: false, null: false, comment: "其他"
    t.boolean "style_lp",                                                 default: false, null: false, comment: "价格低"
    t.boolean "style_hg",                                                 default: false, null: false, comment: "高增长"
    t.boolean "style_hq",                                                 default: false, null: false, comment: "高质量"
    t.boolean "opinion_l",                                                default: false, null: false, comment: "华尔街看多"
    t.boolean "opinion_s",                                                default: false, null: false, comment: "华尔街看空"
    t.boolean "trend_g10",                                                default: false, null: false, comment: "当前价高于十日均线"
    t.boolean "trend_l10",                                                default: false, null: false, comment: "当前价低于十日均线"
    t.boolean "trend_h52",                                                default: false, null: false, comment: "当前价逼近52周最高"
    t.boolean "trend_l52",                                                default: false, null: false, comment: "当前价逼近52周最低"
    t.boolean "consideration_sc",                                         default: false, null: false, comment: "小市值（<十亿美金）"
    t.boolean "consideration_bc",                                         default: false, null: false, comment: "大市值（>百亿美金）"
    t.boolean "consideration_tg",                                         default: false, null: false, comment: "去年盈利且今年展望盈利"
    t.boolean "consideration_bg",                                         default: false, null: false, comment: "盈利反转（去年亏损今年展望盈利）"
    t.boolean "consideration_gg",                                         default: false, null: false, comment: "持续增长（营收及每股盈利展望高于去年）"
    t.boolean "consideration_hg",                                         default: false, null: false, comment: "高增长（营收增长预期 > 16%）"
    t.boolean "consideration_div",                                        default: false, null: false, comment: "有分红"
    t.boolean "consideration_dgc",                                        default: false, null: false, comment: "现金及投资超过借贷的"
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
    t.boolean "country_usa",                                              default: false, null: false
    t.boolean "country_can",                                              default: false, null: false
    t.boolean "country_isr",                                              default: false, null: false
    t.boolean "country_chn",                                              default: false, null: false
    t.boolean "country_others",                                           default: false, null: false
    t.boolean "country_hkg",                                              default: false,              comment: "香港"
    t.boolean "capitalization_pe10",                                      default: false,              comment: "PE < 10"
    t.boolean "capitalization_dy4",                                       default: false,              comment: "股息收益率 > 4%"
    t.boolean "capitalization_clb",                                       default: false,              comment: "市值低于账面价值"
    t.boolean "capitalization_cl1s",                                      default: false,              comment: "市值低于1倍销售额"
    t.boolean "capitalization_cl7p",                                      default: false,              comment: "市值低于7倍经营利润"
    t.decimal "wst_2",                           precision: 18, scale: 6, default: 0.0,                comment: "华尔街目标价格，wst为比例"
    t.decimal "div_2",                           precision: 18, scale: 6, default: 0.0,                comment: "现金分红，div为比例"
    t.decimal "change_rate",                     precision: 10, scale: 6, default: 0.0
  end

  add_index "stock_screeners", ["base_stock_id"], name: "index_stock_screeners_on_base_stock_id", unique: true, using: :btree

  create_table "stock_screeners_copy", force: :cascade do |t|
    t.integer "base_stock_id",       limit: 4,                                            null: false
    t.string  "symbol",              limit: 255
    t.boolean "exchange_us",                                              default: false, null: false, comment: "美股市场"
    t.float   "score",               limit: 24,                           default: 0.0,   null: false, comment: "股票星级"
    t.boolean "exchange_hk",                                              default: false, null: false, comment: "港股市场"
    t.boolean "sector_bm",                                                default: false, null: false, comment: "基础材料"
    t.boolean "sector_c",                                                 default: false, null: false, comment: "综合型大企业"
    t.boolean "sector_cg",                                                default: false, null: false, comment: "消费品"
    t.boolean "sector_f",                                                 default: false, null: false, comment: "金融"
    t.boolean "sector_h",                                                 default: false, null: false, comment: "医疗"
    t.boolean "sector_ig",                                                default: false, null: false, comment: "工业"
    t.boolean "sector_s",                                                 default: false, null: false, comment: "服务业"
    t.boolean "sector_t",                                                 default: false, null: false, comment: "高科技"
    t.boolean "sector_u",                                                 default: false, null: false, comment: "公用事业"
    t.boolean "sector_o",                                                 default: false, null: false, comment: "其他"
    t.boolean "style_lp",                                                 default: false, null: false, comment: "价格低"
    t.boolean "style_hg",                                                 default: false, null: false, comment: "高增长"
    t.boolean "style_hq",                                                 default: false, null: false, comment: "高质量"
    t.boolean "opinion_l",                                                default: false, null: false, comment: "华尔街看多"
    t.boolean "opinion_s",                                                default: false, null: false, comment: "华尔街看空"
    t.boolean "trend_g10",                                                default: false, null: false, comment: "当前价高于十日均线"
    t.boolean "trend_l10",                                                default: false, null: false, comment: "当前价低于十日均线"
    t.boolean "trend_h52",                                                default: false, null: false, comment: "当前价逼近52周最高"
    t.boolean "trend_l52",                                                default: false, null: false, comment: "当前价逼近52周最低"
    t.boolean "consideration_sc",                                         default: false, null: false, comment: "小市值（<十亿美金）"
    t.boolean "consideration_bc",                                         default: false, null: false, comment: "大市值（>百亿美金）"
    t.boolean "consideration_tg",                                         default: false, null: false, comment: "去年盈利且今年展望盈利"
    t.boolean "consideration_bg",                                         default: false, null: false, comment: "盈利反转（去年亏损今年展望盈利）"
    t.boolean "consideration_gg",                                         default: false, null: false, comment: "持续增长（营收及每股盈利展望高于去年）"
    t.boolean "consideration_hg",                                         default: false, null: false, comment: "高增长（营收增长预期 > 16%）"
    t.boolean "consideration_div",                                        default: false, null: false, comment: "有分红"
    t.boolean "consideration_dgc",                                        default: false, null: false, comment: "现金及投资超过借贷的"
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
    t.boolean "country_usa",                                              default: false, null: false
    t.boolean "country_can",                                              default: false, null: false
    t.boolean "country_isr",                                              default: false, null: false
    t.boolean "country_chn",                                              default: false, null: false
    t.boolean "country_others",                                           default: false, null: false
    t.boolean "country_hkg",                                              default: false,              comment: "香港"
    t.boolean "capitalization_pe10",                                      default: false,              comment: "PE < 10"
    t.boolean "capitalization_dy4",                                       default: false,              comment: "股息收益率 > 4%"
    t.boolean "capitalization_clb",                                       default: false,              comment: "市值低于账面价值"
    t.boolean "capitalization_cl1s",                                      default: false,              comment: "市值低于1倍销售额"
    t.boolean "capitalization_cl7p",                                      default: false,              comment: "市值低于7倍经营利润"
    t.decimal "wst_2",                           precision: 18, scale: 6, default: 0.0,                comment: "华尔街目标价格，wst为比例"
    t.decimal "div_2",                           precision: 18, scale: 6, default: 0.0,                comment: "现金分红，div为比例"
  end

  add_index "stock_screeners_copy", ["base_stock_id"], name: "index_stock_screeners_on_base_stock_id", unique: true, using: :btree

  create_table "stocks", force: :cascade do |t|
    t.string   "symbol",              limit: 255
    t.string   "exchange",            limit: 255
    t.string   "company_name",        limit: 255
    t.string   "short_name",          limit: 255
    t.string   "abbrev",              limit: 255
    t.boolean  "active"
    t.boolean  "margin_eligible"
    t.boolean  "etf"
    t.text     "description",         limit: 65535
    t.text     "description_chinese", limit: 65535
    t.string   "industry",            limit: 255
    t.string   "logo",                limit: 255
    t.string   "website",             limit: 255
    t.string   "cusip",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stocks", ["abbrev"], name: "index_stocks_on_abbrev", using: :btree
  add_index "stocks", ["company_name"], name: "index_stocks_on_company_name", using: :btree
  add_index "stocks", ["exchange"], name: "index_stocks_on_exchange", using: :btree
  add_index "stocks", ["industry"], name: "index_stocks_on_industry", using: :btree
  add_index "stocks", ["symbol"], name: "index_stocks_on_symbol", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "feed_id",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "suggest_stocks", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "suggested"
    t.float    "position",   limit: 24
  end

  create_table "suggests", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "image",      limit: 255
    t.integer  "article_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surveys", force: :cascade do |t|
    t.integer  "q1_1",        limit: 4
    t.string   "q1_2",        limit: 255
    t.boolean  "q2"
    t.integer  "q3_1",        limit: 4
    t.integer  "q3_2",        limit: 4
    t.integer  "q3_3",        limit: 4
    t.integer  "q3_4",        limit: 4
    t.string   "q3_5",        limit: 255
    t.text     "q4",          limit: 65535
    t.text     "q5",          limit: 65535
    t.string   "user_name",   limit: 255
    t.string   "user_gender", limit: 255
    t.string   "user_phone",  limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "user_id",     limit: 4
  end

  add_index "surveys", ["user_id"], name: "index_surveys_on_user_id", using: :btree

  create_table "symbol_change_logs", force: :cascade do |t|
    t.integer  "base_stock_id", limit: 4
    t.string   "field",         limit: 255
    t.string   "log",           limit: 255
    t.string   "log_type",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.string   "taggable_type", limit: 16
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.float    "sort",           limit: 24,  default: 0.0
    t.string   "type",           limit: 255
    t.integer  "user_id",        limit: 4
    t.integer  "taggings_count", limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hot",                        default: false
    t.integer  "state",          limit: 4,   default: 0
  end

  add_index "tags", ["state"], name: "index_tags_on_state", using: :btree
  add_index "tags", ["type"], name: "index_tags_on_type", using: :btree

  create_table "target_messages", force: :cascade do |t|
    t.text     "content",    limit: 65535
    t.text     "target",     limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "succ_count", limit: 4
    t.integer  "fail_count", limit: 4
  end

  create_table "time_shares", force: :cascade do |t|
    t.string   "symbol",     limit: 255
    t.integer  "base_id",    limit: 4
    t.decimal  "price",                  precision: 16, scale: 3
    t.integer  "volume",     limit: 8
    t.datetime "time"
    t.boolean  "node"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_articles", force: :cascade do |t|
    t.integer  "topic_id",   limit: 4
    t.integer  "article_id", limit: 4
    t.float    "position",   limit: 24, default: 10000.0
    t.boolean  "visible",               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_baskets", force: :cascade do |t|
    t.integer  "topic_id",   limit: 4
    t.integer  "basket_id",  limit: 4
    t.boolean  "tagged",               default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "topic_baskets", ["topic_id", "basket_id"], name: "index_topic_baskets_on_topic_id_and_basket_id", unique: true, using: :btree

  create_table "topic_news", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "url",        limit: 255
    t.string   "source",     limit: 255
    t.datetime "pub_time"
    t.integer  "topic_id",   limit: 4
    t.float    "position",   limit: 24,  default: 10000.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topic_stocks", force: :cascade do |t|
    t.integer  "topic_id",       limit: 4
    t.integer  "base_stock_id",  limit: 4
    t.float    "position",       limit: 24,    default: 10000.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes",          limit: 65535
    t.integer  "hot_score",      limit: 4,     default: 0
    t.integer  "last_hot_score", limit: 4,     default: 0
    t.boolean  "fixed",                        default: false
    t.boolean  "visible",                      default: false
  end

  add_index "topic_stocks", ["base_stock_id", "fixed", "visible"], name: "idx_topic_stocks_bsid_fixed_visible", using: :btree
  add_index "topic_stocks", ["hot_score"], name: "index_topic_stocks_on_hot_score", using: :btree
  add_index "topic_stocks", ["topic_id", "base_stock_id"], name: "index_topic_stocks_on_topic_id_and_base_stock_id", unique: true, using: :btree
  add_index "topic_stocks", ["topic_id", "fixed"], name: "index_topic_stocks_on_topic_id_and_fixed", using: :btree

  create_table "topics", force: :cascade do |t|
    t.string   "title",                limit: 255
    t.string   "market",               limit: 255
    t.text     "notes",                limit: 65535
    t.string   "img",                  limit: 255
    t.integer  "author_id",            limit: 4
    t.float    "position",             limit: 24,    default: 0.0
    t.integer  "views_count",          limit: 4,     default: 0
    t.string   "basket_ids",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sub_title",            limit: 255
    t.integer  "comments_count",       limit: 4,     default: 0
    t.boolean  "visible",                            default: false
    t.string   "template",             limit: 255
    t.string   "big_img",              limit: 255
    t.integer  "tag_id",               limit: 4
    t.integer  "basket_id",            limit: 4
    t.text     "summary",              limit: 65535
    t.integer  "leading_stocks_count", limit: 4,     default: 0
    t.integer  "baskets_count",        limit: 4,     default: 0
    t.datetime "modified_at"
    t.integer  "follows_count",        limit: 4,     default: 0
  end

  add_index "topics", ["author_id"], name: "index_topics_on_author_id", using: :btree
  add_index "topics", ["market"], name: "index_topics_on_market", using: :btree

  create_table "trading_accounts", force: :cascade do |t|
    t.string   "broker_no",            limit: 255
    t.integer  "user_id",              limit: 4
    t.integer  "broker_id",            limit: 4
    t.integer  "status",               limit: 4
    t.string   "confirmation_token",   limit: 255
    t.datetime "confirmation_sent_at"
    t.string   "email",                limit: 255
    t.string   "password",             limit: 255
    t.integer  "count",                limit: 4
    t.string   "base_currency",        limit: 255
    t.boolean  "portfolioable"
    t.string   "updated_by",           limit: 255
    t.date     "trading_since"
    t.string   "source",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                 limit: 255
    t.string   "cash_id",              limit: 255
    t.date     "audited_date"
    t.date     "actived_date"
    t.datetime "last_login_at"
    t.integer  "parent_id",            limit: 4
    t.integer  "extend_status",        limit: 4
  end

  add_index "trading_accounts", ["broker_no"], name: "index_trading_accounts_on_broker_no", length: {"broker_no"=>15}, using: :btree
  add_index "trading_accounts", ["cash_id"], name: "index_trading_accounts_on_cash_id", using: :btree
  add_index "trading_accounts", ["status"], name: "index_trading_accounts_on_status", using: :btree
  add_index "trading_accounts", ["user_id"], name: "index_trading_accounts_on_user_id", using: :btree

  create_table "tws_orders", force: :cascade do |t|
    t.string   "exchange",     limit: 255
    t.string   "symbol",       limit: 255
    t.integer  "contract_id",  limit: 4
    t.string   "account_name", limit: 255
    t.decimal  "avg_price",                precision: 16, scale: 10
    t.integer  "cum_quantity", limit: 4
    t.decimal  "price",                    precision: 16, scale: 10
    t.integer  "shares",       limit: 4
    t.string   "side",         limit: 255
    t.string   "time",         limit: 255
    t.integer  "ib_order_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "processed"
  end

  create_table "uploads", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.string   "type",          limit: 255
    t.string   "image",         limit: 255
    t.integer  "resource_id",   limit: 4
    t.string   "resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "uploads", ["resource_id", "resource_type"], name: "index_uploads_on_resource_id_and_resource_type", using: :btree
  add_index "uploads", ["type"], name: "index_uploads_on_type", using: :btree
  add_index "uploads", ["user_id"], name: "index_uploads_on_user_id", using: :btree

  create_table "user_bindings", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.string   "broker_user_id", limit: 255
    t.integer  "status",         limit: 4
    t.string   "note",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "available",                  default: true
    t.integer  "count",          limit: 4,   default: 0
    t.string   "base_currency",  limit: 255
    t.boolean  "portfolioable"
    t.string   "updated_by",     limit: 255
    t.integer  "broker_id",      limit: 4
    t.date     "trading_since"
    t.string   "source",         limit: 255
  end

  add_index "user_bindings", ["user_id"], name: "index_user_bindings_on_user_id_and_broker", unique: true, using: :btree

  create_table "user_brokers", force: :cascade do |t|
    t.integer  "user_id",              limit: 4
    t.string   "broker_id",            limit: 255
    t.string   "broker_no",            limit: 255
    t.integer  "status",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_token",   limit: 255
    t.datetime "confirmation_sent_at"
    t.string   "email",                limit: 255
  end

  create_table "user_certifications", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "id_no",      limit: 20,  null: false
    t.string   "real_name",  limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_certifications", ["id_no"], name: "index_user_certifications_on_id_no", unique: true, using: :btree

  create_table "user_counters", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "type",       limit: 255
    t.integer  "amount",     limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_counters", ["type"], name: "index_user_counters_on_type", using: :btree
  add_index "user_counters", ["user_id"], name: "index_user_counters_on_user_id", using: :btree

  create_table "user_day_properties", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.date     "date"
    t.decimal  "total",                          precision: 16, scale: 4
    t.decimal  "total_cash",                     precision: 16, scale: 4
    t.decimal  "total_stocks_cost",              precision: 16, scale: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "base_currency",      limit: 255
    t.integer  "trading_account_id", limit: 4
  end

  add_index "user_day_properties", ["trading_account_id", "user_id", "date"], name: "unique_index_for_user_properties", unique: true, using: :btree
  add_index "user_day_properties", ["user_id", "date"], name: "index_user_day_properties_on_user_id_and_date", using: :btree
  add_index "user_day_properties", ["user_id"], name: "index_user_day_properties_on_user_id", using: :btree

  create_table "user_profits", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.decimal  "today_pnl",                    precision: 16, scale: 3, default: 0.0
    t.decimal  "total_pnl",                    precision: 16, scale: 3, default: 0.0
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "trading_account_id", limit: 4
  end

  add_index "user_profits", ["date"], name: "index_user_profits_on_date", using: :btree
  add_index "user_profits", ["trading_account_id", "date"], name: "index_user_profits_on_trading_account_id_and_date", unique: true, using: :btree
  add_index "user_profits", ["trading_account_id"], name: "index_user_profits_on_trading_account_id", using: :btree
  add_index "user_profits", ["user_id"], name: "index_user_profits_on_user_id", using: :btree

  create_table "user_providers", force: :cascade do |t|
    t.string  "provider_id", limit: 100
    t.string  "provider",    limit: 100
    t.integer "user_id",     limit: 4
    t.text    "ext",         limit: 65535
    t.boolean "active",                    default: true
  end

  add_index "user_providers", ["provider_id", "provider"], name: "index_user_providers_on_provider_id_and_provider", using: :btree

  create_table "user_stock_profits", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.integer  "trading_account_id", limit: 4
    t.integer  "stock_id",           limit: 4
    t.date     "date"
    t.float    "total_pnl",          limit: 24
    t.float    "today_pnl",          limit: 24
    t.float    "total_buyed",        limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_stock_profits", ["user_id", "trading_account_id", "stock_id"], name: "idx_of_user_stock_profits", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                   limit: 191
    t.string   "username",                limit: 191
    t.string   "avatar",                  limit: 255
    t.string   "logo",                    limit: 255
    t.boolean  "gender"
    t.integer  "province",                limit: 8
    t.string   "city",                    limit: 50
    t.string   "biography",               limit: 255
    t.integer  "invitation_id",           limit: 4
    t.integer  "invitation_limit",        limit: 4,                            default: 0
    t.boolean  "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password",      limit: 255,                          default: "",    null: false
    t.string   "reset_password_token",    limit: 191
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           limit: 4,                            default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",      limit: 255
    t.string   "last_sign_in_ip",         limit: 255
    t.string   "confirmation_token",      limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "role_id",                 limit: 4
    t.integer  "follows_count",           limit: 4,                            default: 0
    t.integer  "baskets_count",           limit: 4,                            default: 0
    t.integer  "confirmation_count",      limit: 4,                            default: 0
    t.string   "unconfirmed_email",       limit: 255
    t.boolean  "is_company_user",                                              default: false
    t.boolean  "available",                                                    default: true
    t.string   "invite_code",             limit: 255
    t.integer  "followed_users_count",    limit: 4,                            default: 0
    t.string   "headline",                limit: 255
    t.decimal  "basket_fluctuation",                  precision: 20, scale: 8, default: 0.0
    t.string   "mobile",                  limit: 191
    t.string   "source",                  limit: 255
    t.datetime "checked_at"
    t.string   "rebind_email",            limit: 255
    t.string   "rebind_email_token",      limit: 255
    t.datetime "rebind_email_sent_at"
    t.string   "channel_code",            limit: 100
    t.integer  "following_baskets_count", limit: 4,                            default: 0
    t.integer  "following_stocks_count",  limit: 4,                            default: 0
    t.integer  "status",                  limit: 4,                            default: 0
  end

  add_index "users", ["baskets_count"], name: "index_users_on_baskets_count", using: :btree
  add_index "users", ["channel_code"], name: "index_users_on_channel_code", using: :btree
  add_index "users", ["city"], name: "index_users_on_city", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["follows_count"], name: "index_users_on_follows_count", using: :btree
  add_index "users", ["mobile"], name: "index_users_on_mobile", unique: true, using: :btree
  add_index "users", ["province"], name: "index_users_on_province", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["role_id"], name: "index_users_on_role_id", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "entry_id",   limit: 4
    t.string   "type",       limit: 255
    t.integer  "rating",     limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "yahoo_logs", force: :cascade do |t|
    t.integer  "base_id",    limit: 4
    t.string   "code",       limit: 255
    t.text     "message",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "yahoo_rt_logs", force: :cascade do |t|
    t.string "message", limit: 255
  end

  add_index "yahoo_rt_logs", ["message"], name: "index_yahoo_rt_logs_on_message", using: :btree

end
