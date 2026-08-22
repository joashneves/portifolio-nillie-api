# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_21_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "categoria_de_imagens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "imagem_caminho"
    t.string "nome"
    t.integer "ordem", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["ordem"], name: "index_categoria_de_imagens_on_ordem"
  end

  create_table "imagens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "categoria_de_imagens_id"
    t.datetime "created_at", null: false
    t.string "descricao"
    t.string "imagem_caminho"
    t.string "nome"
    t.datetime "updated_at", null: false
    t.index ["categoria_de_imagens_id"], name: "index_imagens_on_categoria_de_imagens_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "password_digest"
    t.string "token"
    t.datetime "updated_at", null: false
    t.string "username"
  end

  add_foreign_key "imagens", "categoria_de_imagens", column: "categoria_de_imagens_id"
end
