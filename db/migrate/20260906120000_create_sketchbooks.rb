class CreateSketchbooks < ActiveRecord::Migration[8.1]
  def change
    create_table :sketchbooks, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :nome
      t.string :imagem_caminho
      t.integer :ordem, default: 0, null: false

      t.timestamps
    end

    add_index :sketchbooks, :ordem
  end
end