# =============================================================================
# Modelo: Imagen
# =============================================================================
# Representa uma imagem dentro de uma categoria do portfólio.
# Cada imagem pertence a uma categoria e possui nome, descrição e arquivo.
#
# Tabela: "imagens"
#   - id: UUID (chave primária gerada automaticamente via pgcrypto)
#   - categoria_de_imagens_id: UUID (chave estrangeira → tabela "categoria_de_imagens")
#   - nome: string (nome da imagem, opcional)
#   - descricao: string (descrição da imagem, opcional, máx 500 chars)
#   - imagem_caminho: string (nome do arquivo salvo em public/uploads/)
#   - created_at / updated_at: timestamps
#
# Associações:
#   - belongs_to :categoria_de_imagen → Cada imagem pertence a uma categoria
#     foreign_key: :categoria_de_imagens_id → coluna FK nesta tabela
#
# Validações:
#   - nome: opcional (allow_blank), máx 100 caracteres
#   - descricao: opcional (allow_blank), máx 500 caracteres
#   - imagem_caminho: obrigatório (validação customizada)
#
# Armazenamento:
#   Mesma lógica que CategoriaDeImagen: arquivo salvo em public/uploads/,
#   nome do arquivo em imagem_caminho, URL montada no método imagem_url.
# =============================================================================

class Imagen < ApplicationRecord
  # Associação: cada imagem pertence a uma categoria
  # foreign_key: especifica qual coluna nesta tabela referencia a categoria
  belongs_to :categoria_de_imagen, foreign_key: :categoria_de_imagens_id

  # Validações opcionais (allow_blank permite campos vazios)
  validates :nome, length: { maximum: 100 }, allow_blank: true
  validates :descricao, length: { maximum: 500 }, allow_blank: true

  # Validação customizada: garante que uma imagem foi enviada
  validate :imagem_caminho_present

  # Monta a URL completa da imagem para acesso via HTTP
  # Exemplo: "http://localhost:3000/uploads/f7e8d9c0b1a2.webp"
  def imagem_url
    return unless imagem_caminho.present?

    "#{ENV.fetch('API_HOST', 'http://localhost:3000')}/uploads/#{imagem_caminho}"
  end

  private

  # Validação customizada: verifica se imagem_caminho está preenchido
  def imagem_caminho_present
    errors.add(:imagem, 'precisa ser enviada') unless imagem_caminho.present?
  end
end
