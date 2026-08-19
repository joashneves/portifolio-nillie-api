# =============================================================================
# Controller: UsersController
# =============================================================================
# Gerencia dados do usuário logado (perfil).
#
# Rotas:
#   GET    /user              → show       (autenticado)
#   PATCH  /user              → update     (autenticado)
#   POST   /user/update_avatar → update_avatar (autenticado)
#
# Nota: usa resource (singular) em vez de resources (plural)
# Isso gera rotas como /user em vez de /user/:id
# O usuário é identificado pelo token, não pelo ID na URL
# =============================================================================

class UsersController < ApplicationController
  # GET /user
  # Retorna os dados do usuário logado
  def show
    render json: {
      user: {
        id: current_user.id,
        username: current_user.username,
        avatar_url: current_user.avatar_url
      }
    }
  end

  # PATCH /user
  # Atualiza dados do usuário logado (username, senha)
  def update
    if current_user.update(user_params)
      render json: {
        user: {
          id: current_user.id,
          username: current_user.username,
          avatar_url: current_user.avatar_url
        }
      }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /user/update_avatar
  # Atualiza o avatar do usuário (funcionalidade futura)
  def update_avatar
    if params[:avatar].present?
      current_user.avatar.attach(params[:avatar])
      render json: {
        user: {
          id: current_user.id,
          username: current_user.username,
          avatar_url: current_user.avatar_url
        }
      }
    else
      render json: { error: "No image provided" }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:username, :password, :password_confirmation)
  end
end
