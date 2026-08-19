# =============================================================================
# Controller: ApplicationController
# =============================================================================
# Controller base de onde todos os outros herdam.
# Responsável por configurar a autenticação padrão da API.
#
# Como funciona a autenticação:
#   1. Todo request passa pelo before_action :authenticate_user!
#   2. O método lê o header "Authorization: Bearer <token>"
#   3. Busca o usuário no banco pelo token
#   4. Se não encontrar, retorna 401 Unauthorized
#   5. Controllers filhos podem pular a autenticação com skip_before_action
#
# Fluxo de um request autenticado:
#   Frontend → Header "Authorization: Bearer abc123..."
#   → ApplicationController#authenticate_user!
#   → User.find_by(token: "abc123...")
#   → Se encontrado: continua para a action do controller filho
#   → Se não encontrado: retorna { error: "Unauthorized" } (401)
# =============================================================================

class ApplicationController < ActionController::API
  # before_action roda um método ANTES de cada action do controller
  # Por padrão, todos os controllers herdam este comportamento
  # Controllers podem pular com: skip_before_action :authenticate_user!, only: [...]
  before_action :authenticate_user!

  private

  # Verifica se o request tem um token válido no header Authorization
  # request.headers["Authorization"] → pega o valor do header
  # &.split(" ") → separa "Bearer abc123" em ["Bearer", "abc123"]
  # &.last → pega o último elemento ("abc123")
  # O &. é o "safe navigation operator" do Ruby (evita erro se for nil)
  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    @current_user = User.find_by(token: token)
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  # Retorna o usuário logado (usado em outros controllers)
  def current_user
    @current_user
  end
end
