class Sketchbook < ApplicationRecord
  validates :nome, presence: true, length: { maximum: 100 }
  validate :imagem_caminho_present

  has_many :imagens_de_sketchbooks, class_name: "ImagemDeSketchbook", foreign_key: :sketchbook_id, dependent: :delete_all

  def imagem_url
    return unless imagem_caminho.present?

    "#{ENV.fetch('API_HOST', 'http://localhost:3000')}/uploads/#{imagem_caminho}"
  end

  private

  def imagem_caminho_present
    errors.add(:imagem, 'precisa ser enviada') unless imagem_caminho.present?
  end
end