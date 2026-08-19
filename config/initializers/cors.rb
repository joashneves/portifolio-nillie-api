# =============================================================================
# Configuração CORS (config/initializers/cors.rb)
# =============================================================================
# CORS = Cross-Origin Resource Sharing
# Permite que o frontend (rodando em outra porta/origem) acesse a API.
#
# Sem esta configuração, o navegador bloqueia requisições do frontend
# para a API por política de segurança (Same-Origin Policy).
#
# Configuração atual:
#   - Permite requisições apenas da origem definida em FRONTEND_URL
#   - Se FRONTEND_URL não estiver definida, usa http://localhost:5173
#   - Permite todos os métodos HTTP (GET, POST, PUT, DELETE, etc.)
#   - Permite qualquer header (incluindo Authorization para autenticação)
#
# Variáveis de ambiente:
#   - FRONTEND_URL: URL do frontend (definida no .env da API)
#   - Exemplo: FRONTEND_URL=http://localhost:5173
# =============================================================================

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Só permite requisições do frontend definido no .env
    origins ENV.fetch("FRONTEND_URL", "http://localhost:5173")

    resource "*",
      headers: :any,    # Permite qualquer header (Authorization, Content-Type, etc.)
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]  # Todos os métodos HTTP
  end
end
