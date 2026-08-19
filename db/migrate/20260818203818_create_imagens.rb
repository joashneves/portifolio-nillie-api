class CreateImagens < ActiveRecord::Migration[8.1]
  def change
    create_table :imagens do |t|
      t.references :categoria_de_imagens, null: false, foreign_key: true
      t.string :nome
      t.string :descricao
      t.string :imagem_caminho

      t.timestamps
    end
  end
end
