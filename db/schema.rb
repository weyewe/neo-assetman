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

ActiveRecord::Schema.define(version: 20130919025936) do

  create_table "customers", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", force: true do |t|
    t.string   "name"
    t.string   "code"
    t.text     "description"
    t.integer  "ready",            default: 0
    t.integer  "pending_receival", default: 0
    t.integer  "pending_delivery", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchase_order_entries", force: true do |t|
    t.integer  "purchase_order_id"
    t.integer  "quantity",          default: 0
    t.integer  "pending_receival"
    t.integer  "received",          default: 0
    t.integer  "item_id"
    t.boolean  "is_confirmed",      default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchase_orders", force: true do |t|
    t.integer  "supplier_id"
    t.datetime "purchased_at"
    t.integer  "warehouse_id"
    t.text     "description"
    t.boolean  "is_confirmed", default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchase_receival_entries", force: true do |t|
    t.integer  "purchase_receival_id"
    t.integer  "quantity",                default: 0
    t.integer  "purchase_order_entry_id"
    t.boolean  "is_confirmed",            default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchase_receivals", force: true do |t|
    t.integer  "supplier_id"
    t.text     "description"
    t.datetime "received_at"
    t.boolean  "is_confirmed", default: false
    t.string   "code"
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchase_return_entries", force: true do |t|
    t.integer  "purchase_return_id"
    t.integer  "quantity",                default: 0
    t.integer  "purchase_order_entry_id"
    t.boolean  "is_confirmed",            default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchase_returns", force: true do |t|
    t.integer  "supplier_id"
    t.text     "description"
    t.datetime "received_at"
    t.boolean  "is_confirmed", default: false
    t.string   "code"
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sales_deliveries", force: true do |t|
    t.integer  "customer_id"
    t.text     "description"
    t.datetime "delivered_at"
    t.boolean  "is_confirmed", default: false
    t.string   "code"
    t.datetime "confirmed_at"
    t.integer  "warehouse_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sales_delivery_entries", force: true do |t|
    t.integer  "sales_delivery_id"
    t.integer  "quantity",             default: 0
    t.integer  "sales_order_entry_id"
    t.boolean  "is_confirmed",         default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sales_order_entries", force: true do |t|
    t.integer  "sales_order_id"
    t.integer  "quantity",         default: 0
    t.integer  "pending_delivery"
    t.integer  "delivered",        default: 0
    t.integer  "item_id"
    t.boolean  "is_confirmed",     default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sales_orders", force: true do |t|
    t.integer  "customer_id"
    t.datetime "sold_at"
    t.text     "description"
    t.boolean  "is_confirmed", default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sales_return_entries", force: true do |t|
    t.integer  "sales_return_id"
    t.integer  "quantity",             default: 0
    t.integer  "sales_order_entry_id"
    t.boolean  "is_confirmed",         default: false
    t.datetime "confirmed_at"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sales_returns", force: true do |t|
    t.integer  "customer_id"
    t.text     "description"
    t.datetime "received_at"
    t.boolean  "is_confirmed", default: false
    t.string   "code"
    t.datetime "confirmed_at"
    t.integer  "warehouse_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stock_adjustments", force: true do |t|
    t.integer  "item_id"
    t.integer  "warehouse_id"
    t.integer  "warehouse_item_id"
    t.integer  "actual_quantity",   default: 0
    t.integer  "initial_quantity",  default: 0
    t.integer  "diff",              default: 0
    t.boolean  "is_confirmed",      default: false
    t.string   "code"
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stock_mutations", force: true do |t|
    t.integer  "warehouse_item_id"
    t.integer  "warehouse_id"
    t.integer  "item_id"
    t.integer  "quantity"
    t.integer  "case",                       default: 1
    t.integer  "stock_mutation_source_id"
    t.string   "stock_mutation_source_type"
    t.datetime "mutated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "suppliers", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "warehouse_item_mutations", force: true do |t|
    t.integer  "source_warehouse_id"
    t.integer  "target_warehouse_id"
    t.integer  "quantity"
    t.integer  "item_id"
    t.boolean  "is_confirmed",        default: false
    t.string   "code"
    t.datetime "confirmed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "warehouse_items", force: true do |t|
    t.integer  "item_id"
    t.integer  "warehouse_id"
    t.integer  "ready",            default: 0
    t.integer  "pending_receival", default: 0
    t.integer  "pending_delivery", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "warehouses", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
