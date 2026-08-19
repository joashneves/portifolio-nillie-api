# =============================================================================
# Controller: ImagensController
# =============================================================================
# Gerencia as imagens dentro de uma categoria (CRUD completo).
# Rotas aninhadas: /categorias_de_imagens/:categorias_de_imagen_id/imagens
#
# Rotas geradas por resources :imagens (nested):
#   GET    /categorias_de_imagens/:cat_id/imagens          → index  (público)
#   GET    /categorias_de_imagens/:cat_id/imagens/:id      → show   (público)
#   POST   /categorias_de_imagens/:cat_id/imagens          → create (autenticado)
#   PATCH  /categorias_de_imagens/:cat_id/imagens/:id      → update (autenticado)
#   DELETE /categorias_de_imagens/:cat_id/imagens/:id      → destroy (autenticado)
#
# Diferença do CategoriasDeImagensController:
#   - Este controller trabalha com imagens INDIVIDUAIS dentro de uma categoria
#   - A categoria é carregada automaticamente via :set_categoria (before_action)
#   - As rotas são aninhadas (nested resources)
# =============================================================================

class ImagensController < ApplicationController
  # index e show são públicos (portfolio visível sem login)
  skip_before_action :authenticate_user!, only: [ :index, :show ]

  # Sempre carrega a categoria pai antes de qualquer action
  before_action :set_categoria

  # Carrega a imagem individual para show, update e destroy
  before_action :set_imagen, only: [ :show, :update, :destroy ]

  # GET /categorias_de_imagens/:cat_id/imagens
  # Lista todas as imagens de uma categoria
  def index
    imagens = @categoria.imagens
    render json: imagens.map { |i| imagen_json(i) }
  end

  # GET /categorias_de_imagens/:cat_id/imagens/:id
  # Retorna detalhes de uma imagem específica
  def show
    render json: imagen_json(@imagen)
  end

  # POST /categorias_de_imagens/:cat_id/imagens
  # Cria uma nova imagem dentro da categoria
  def create
    # new + save é o padrão Rails para criar registros
    imagen = @categoria.imagens.new(imagen_params)
    save_image(imagen) # Processa e salva o arquivo

    if imagen.save
      render json: imagen_json(imagen), status: :created
    else
      render json: { errors: imagen.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /categorias_de_imagens/:cat_id/imagens/:id
  # Atualiza uma imagem existente
  def update
    save_image(@imagen) if params[:imagem].present?

    if @imagen.update(imagen_params)
      render json: imagen_json(@imagen)
    else
      render json: { errors: imagen.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /categorias_de_imagens/:cat_id/imagens/:id
  # Deleta uma imagem e seu arquivo físico
  def destroy
    delete_image(@imagen.imagem_caminho)
    @imagen.destroy
    head :no_content
  end

  private

  # Busca a categoria pai pelo parâmetro da URL
  # params[:categorias_de_imagen_id] → o ID da categoria na URL
  # Exemplo: /categorias_de_imagens/abc123/imagens
  #          params[:categorias_de_imagen_id] = "abc123"
  def set_categoria
    @categoria = CategoriaDeImagen.find(params[:categorias_de_imagen_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Category not found" }, status: :not_found
  end

  # Busca a imagem específica dentro da categoria
  # .find garante que a imagem pertence à categoria correta (segurança)
  def set_imagen
    @imagen = @categoria.imagens.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Image not found" }, status: :not_found
  end

  # Strong Parameters: campos permitidos para imagens
  def imagen_params
    params.permit(:nome, :descricao)
  end

  # Salva a imagem enviada (mesma lógica do CategoriasDeImagensController)
  # Converte para .webp e salva em public/uploads/
  def save_image(record)
    return unless params[:imagem].present?

    delete_image(record.imagem_caminho) if record.imagem_caminho.present?

    uploaded = params[:imagem]
    filename = "#{SecureRandom.hex(8)}.webp"
    filepath = Rails.root.join("public", "uploads", filename)

    FileUtils.mkdir_p(File.dirname(filepath))

    if uploaded.original_filename.end_with?(".webp")
      File.binwrite(filepath, uploaded.read)
    else
      tmp = Tempfile.new([ "upload", File.extname(uploaded.original_filename) ])
      tmp.binmode
      tmp.write(uploaded.read)
      tmp.rewind

      processed = ImageProcessing::MiniMagick.source(tmp).convert("webp").call
      File.binwrite(filepath, IO.binread(processed.path))

      tmp.close
      tmp.unlink
    end

    record.imagem_caminho = filename
  end

  # Deleta arquivo de imagem do disco
  def delete_image(caminho)
    return unless caminho.present?

    path = Rails.root.join("public", "uploads", caminho)
    File.delete(path) if File.exist?(path)
  end

  # Monta o JSON de resposta para uma imagem
  def imagen_json(imagen)
    {
      id: imagen.id,
      nome: imagen.nome,
      descricao: imagen.descricao,
      imagem_url: imagen.imagem_url,
      categoria_de_imagen_id: imagen.categoria_de_imagens_id,
      created_at: imagen.created_at,
      updated_at: imagen.updated_at
    }
  end
end
