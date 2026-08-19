# =============================================================================
# Modelo: User
# =============================================================================
# Representa um usuário do sistema (admin ou não).
# Usado para autenticação e controle de acesso ao painel administrativo.
#
# Tabela: "users"
#   - id: UUID (chave primária)
#   - username: string (nome de usuário, único, 3-30 caracteres)
#   - password_digest: string (hash da senha, gerado pelo bcrypt)
#   - token: string (token de autenticação, 64 caracteres hexadecimais)
#   - admin: boolean (true = administrador, false = usuário comum)
#   - created_at / updated_at: timestamps
#
# Gem bcrypt (has_secure_password):
#   - Cria automaticamente os campos password e password_confirmation
#   - Armazena a senha criptografada em password_digest (nunca em texto puro)
#   - Fornece o método authenticate(senha) que verifica se a senha está correta
#
# Autenticação via Token:
#   - Ao fazer login, um novo token é gerado (regenerate_token)
#   - O token é enviado no header Authorization: Bearer <token>
#   - Ao fazer logout, o token é setado como nil (invalidado)
#
# Primeiro usuário:
#   - O primeiro usuário a se registrar automaticamente se torna admin
#   - Usuários subsequentes precisam de um admin para criar contas
# =============================================================================

class User < ApplicationRecord
  # has_secure_password (da gem bcrypt):
  #   - Adiciona validação de presença para password
  #   - Cria atributos virtuais password e password_confirmation
  #   - Criptografa a senha automaticamente e salva em password_digest
  #   - Fornece o método authenticate para verificar a senha
  has_secure_password

  # Validações
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 }

  # Método público: retorna se o usuário é admin
  # Usado para verificar permissões (ex: quem pode criar novos usuários)
  def admin?
    admin
  end

  # Callback: antes de criar um novo usuário, gera um token automaticamente
  # before_create → roda uma vez, logo antes do primeiro INSERT no banco
  before_create :generate_token

  # Regenera o token de autenticação (chamado no login)
  # update! salva no banco e lança exceção se falhar
  # SecureRandom.hex(32) gera 64 caracteres hexadecimais aleatórios
  def regenerate_token
    update!(token: SecureRandom.hex(32))
    token
  end

  # Placeholder para URL do avatar (futura implementação)
  def avatar_url
    nil
  end

  private

  # Gera um token único para o usuário (roda antes do primeiro save)
  # self.token = atribui o valor ao campo token da instância
  def generate_token
    self.token = SecureRandom.hex(32)
  end
end
