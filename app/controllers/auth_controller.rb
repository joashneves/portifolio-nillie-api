# =============================================================================
# Controller: AuthController
# =============================================================================
# Gerencia autenticação: registro, login e logout de usuários.
#
# Rotas:
#   POST /auth/register  → register  (público, com restrição para novos usuários)
#   POST /auth/login     → login     (público)
#   DELETE /auth/logout   → logout    (autenticado)
#
# Fluxo de autenticação:
#   1. Usuário faz POST /auth/login com username e password
#   2. O controller verifica as credenciais com authenticate (bcrypt)
#   3. Se corretas, gera um novo token e retorna ele no JSON
#   4. O frontend salva o token (localStorage) e envia em cada request
#   5. O ApplicationController verifica o token no header Authorization
#
# Controle de acesso para registro:
#   - Se não existe nenhum usuário no banco → qualquer um pode se registrar
#   - O primeiro usuário registrado automaticamente se torna admin
#   - Se já existem usuários → apenas um admin pode criar novos usuários
#     (precisa enviar o token do admin no header Authorization)
# =============================================================================

class AuthController < ApplicationController
  # Pula autenticação para register e login (senão seria impossível logar)
  skip_before_action :authenticate_user!, only: [ :register, :login ]

  # POST /auth/register
  # Cria um novo usuário
  def register
    # Se já existem usuários no sistema, verificar se quem está criando é admin
    if User.exists?
      token = request.headers["Authorization"]&.split(" ")&.last
      admin_user = User.find_by(token: token)

      # Se não encontrou admin com esse token, retorna 403 Forbidden
      unless admin_user&.admin?
        return render json: { error: "Only admin can create new users" }, status: :forbidden
      end
    end

    user = User.new(register_params)

    # Se é o primeiro usuário do sistema, torna-se admin automaticamente
    user.admin = true if User.count == 0

    if user.save
      render json: {
        user: {
          id: user.id,
          username: user.username,
          admin: user.admin?,
          token: user.token,        # Token gerado automaticamente pelo before_create
          avatar_url: user.avatar_url
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /auth/login
  # Autentica um usuário e retorna um token
  def login
    user = User.find_by(username: params[:username])

    # authenticate é um método do bcrypt que compara a senha com o hash
    # Retorna true se a senha estiver correta, false caso contrário
    if user&.authenticate(params[:password])
      # Regenera o token (invalida o anterior se existir)
      user.regenerate_token
      render json: {
        user: {
          id: user.id,
          username: user.username,
          admin: user.admin?,
          token: user.token,
          avatar_url: user.avatar_url
        }
      }
    else
      render json: { error: "Username or password invalid" }, status: :unauthorized
    end
  end

  # DELETE /auth/logout
  # Invalida o token do usuário (requer autenticação)
  def logout
    # Seta o token como nil → o token anterior deixa de funcionar
    current_user.update!(token: nil)
    render json: { message: "Logged out successfully" }
  end

  private

  # Strong Parameters para registro
  def register_params
    params.permit(:username, :password, :password_confirmation)
  end
end
