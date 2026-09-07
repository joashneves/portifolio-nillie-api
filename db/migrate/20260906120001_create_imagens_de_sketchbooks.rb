class CreateImagensDeSketchbooks < ActiveRecord::Migration[8.1]
  def change
    create_table :imagens_de_sketchbooks, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :sketchbook, null: false, foreign_key: true, type: :uuid
      t.string :nome
      t.string :descricao
      t.string :imagem_caminho

      t.timestamps
    end
  end
end