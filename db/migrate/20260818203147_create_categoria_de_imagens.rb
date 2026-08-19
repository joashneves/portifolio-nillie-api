class CreateCategoriaDeImagens < ActiveRecord::Migration[8.1]
  def change
    create_table :categoria_de_imagens do |t|
      t.string :nome
      t.string :imagem_caminho

      t.timestamps
    end
  end
end
