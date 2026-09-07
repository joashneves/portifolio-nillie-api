class ImagemDeSketchbook < ApplicationRecord
  self.table_name = 'imagens_de_sketchbooks'

  belongs_to :sketchbook, foreign_key: :sketchbook_id

  validates :nome, length: { maximum: 100 }, allow_blank: true
  validates :descricao, length: { maximum: 500 }, allow_blank: true
  validate :imagem_caminho_present

  def imagem_url
    return unless imagem_caminho.present?

    "#{ENV.fetch('API_HOST', 'http://localhost:3000')}/uploads/#{imagem_caminho}"
  end

  private

  def imagem_caminho_present
    errors.add(:imagem, 'precisa ser enviada') unless imagem_caminho.present?
  end
end