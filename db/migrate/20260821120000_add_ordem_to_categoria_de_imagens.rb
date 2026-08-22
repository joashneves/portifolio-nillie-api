class AddOrdemToCategoriaDeImagens < ActiveRecord::Migration[8.0]
  def change
    add_column :categoria_de_imagens, :ordem, :integer, default: 0, null: false
    add_index :categoria_de_imagens, :ordem
  end
end
