# =============================================================================
# Modelo: CategoriaDeImagen
# =============================================================================
# Representa uma categoria de imagens no portfólio. Cada categoria agrupa
# várias imagens e possui uma imagem de capa (thumbnail).
#
# Tabela: "categoria_de_imagens"
#   - id: UUID (chave primária gerada automaticamente via pgcrypto)
#   - nome: string (nome da categoria, ex: "Paisagens", "Retratos")
#   - imagem_caminho: string (nome do arquivo da imagem salva em public/uploads/)
#   - created_at / updated_at: timestamps
#
# Associações:
#   - has_many :imagens → Uma categoria pode ter muitas imagens
#     foreign_key: :categoria_de_imagens_id → coluna FK na tabela "imagens"
#     dependent: :delete_all → Ao deletar a categoria, deleta todas as imagens filhas
#
# Validações:
#   - nome: obrigatório, máximo 100 caracteres
#   - imagem_caminho: obrigatório (validação customizada via imagem_caminho_present)
#
# Como funciona o armazenamento de imagens:
#   As imagens são salvas fisicamente em public/uploads/ com nomes aleatórios
#   (ex: a1b2c3d4e5f6.webp). A coluna imagem_caminho guarda APENAS o nome do
#   arquivo. A URL completa é montada no método imagem_url.
#
# Nota sobre UUID:
#   O Rails inflecta "CategoriaDeImagen" → plural "CategoriaDeImagens".
#   A tabela se chama "categoria_de_imagens" (plural), o que confere.
# =============================================================================

class CategoriaDeImagen < ApplicationRecord
  # Associação: uma categoria tem muitas imagens
  # foreign_key: especifica qual coluna na tabela "imagens" referencia esta categoria
  # dependent: :delete_all → deleta as imagens filhas quando a categoria é removida
  has_many :imagens, foreign_key: :categoria_de_imagens_id, dependent: :delete_all

  # Validações do ActiveRecord
  # validates → verifica regras antes de salvar no banco
  # presence: true → o campo não pode ser vazio/nulo
  # length: { maximum: 100 } → no máximo 100 caracteres
  validates :nome, presence: true, length: { maximum: 100 }

  # Validação customizada: garante que uma imagem foi enviada
  # validate → chama um método que adiciona erros manualmente
  validate :imagem_caminho_present

  # Monta a URL completa da imagem para acesso via HTTP
  # Exemplo: "http://localhost:3000/uploads/a1b2c3d4.webp"
  # ENV.fetch pega o valor da variável de ambiente API_HOST, com fallback
  def imagem_url
    return unless imagem_caminho.present?

    "#{ENV.fetch('API_HOST', 'http://localhost:3000')}/uploads/#{imagem_caminho}"
  end

  private

  # Validação customizada: verifica se imagem_caminho está preenchido
  # errors.add adiciona uma mensagem de erro que aparece na resposta da API
  def imagem_caminho_present
    errors.add(:imagem, 'precisa ser enviada') unless imagem_caminho.present?
  end
end
