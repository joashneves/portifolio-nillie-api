# =============================================================================
# Rotas da API (config/routes.rb)
# =============================================================================
# Define todas as rotas (endpoints) da aplicação Rails.
# Cada rota mapeia uma URL para uma action de um controller.
#
# Como funciona o Rails Router:
#   - "resources :categorias_de_imagens" gera 7 rotas padrão REST:
#     GET /categorias_de_imagens          → index
#     GET /categorias_de_imagens/:id      → show
#     POST /categorias_de_imagens         → create
#     PATCH /categorias_de_imagens/:id    → update
#     DELETE /categorias_de_imagens/:id   → destroy
#     GET /categorias_de_imagens/new      → new (não usado em API)
#     GET /categorias_de_imagens/:id/edit → edit (não usado em API)
#
#   - "resources :imagens" dentro de "resources" cria rotas aninhadas:
#     GET /categorias_de_imagens/:cat_id/imagens
#     POST /categorias_de_imagens/:cat_id/imagens
#     etc.
#
# Rotas de autenticação:
#   - "namespace :auth" agrupa as rotas sob /auth/
#   - register e login são POST (enviam dados)
#   - logout é DELETE (invalida o token)
#
# Health check:
#   - GET /up → verifica se a API está funcionando
# =============================================================================

Rails.application.routes.draw do
  # Health check endpoint (usado por load balancers e monitors)
  get "up" => "rails/health#show", as: :rails_health_check

  # Rotas de autenticação (login, registro, logout)
  # Todas ficam sob o namespace /auth/
  namespace :auth do
    post :register   # POST /auth/register
    post :login      # POST /auth/login
    delete :logout   # DELETE /auth/logout
  end

  # Rotas do usuário logado (singular resource)
  # GET /user → ver perfil
  # PATCH /user → atualizar perfil
  # POST /user/update_avatar → atualizar avatar
  resource :user, only: [ :show, :update ] do
    post :update_avatar
  end

  # Rotas de categorias de imagens (CRUD completo)
  # Rotas aninhadas: imagens ficam dentro de categorias
  # GET /categorias_de_imagens → listar todas
  # GET /categorias_de_imagens/:id → ver detalhes + imagens
  # POST /categorias_de_imagens → criar (autenticado)
  # PATCH /categorias_de_imagens/:id → atualizar (autenticado)
  # DELETE /categorias_de_imagens/:id → deletar (autenticado)
  resources :categorias_de_imagens do
    resources :imagens
  end

  resources :colecaos
end
