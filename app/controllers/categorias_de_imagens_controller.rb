# =============================================================================
# Controller: CategoriasDeImagensController
# =============================================================================
# Gerencia as categorias de imagens do portfólio (CRUD completo).
#
# Rotas geradas por resources :categorias_de_imagens:
#   GET    /categorias_de_imagens          → index  (público)
#   GET    /categorias_de_imagens/:id      → show   (público)
#   POST   /categorias_de_imagens          → create (autenticado)
#   PATCH  /categorias_de_imagens/:id      → update (autenticado)
#   DELETE /categorias_de_imagens/:id      → destroy (autenticado)
#
# Fluxo de upload de imagem:
#   1. Frontend envia FormData com campo "imagem" (arquivo) e "nome" (texto)
#   2. Controller recebe o arquivo em params[:imagem]
#   3. save_image() converte para .webp (se necessário) e salva em public/uploads/
#   4. O nome do arquivo é gravado na coluna imagem_caminho do banco
#   5. O modelo monta a URL completa quando imagem_url é chamado
#
# Gerenciamento de armazenamento:
#   - Ao atualizar: a imagem antiga é deletada antes de salvar a nova
#   - Ao deletar: o arquivo físico é removido do public/uploads/
# =============================================================================

class CategoriasDeImagensController < ApplicationController
  # skip_before_action pula a verificação de token para actions públicas
  # index (listar) e show (ver detalhes) não precisam de login
  skip_before_action :authenticate_user!, only: [ :index, :show ]

  # before_action roda set_categoria ANTES de show, update e destroy
  # Busca a categoria pelo ID e retorna 404 se não encontrar
  before_action :set_categoria, only: [ :show, :update, :destroy ]

  # GET /categorias_de_imagens
  # Lista todas as categorias com contagem de imagens
  def index
    # includes(:imagens) → eager loading (evita N+1 queries)
    # Sem isso, cada categoria faria uma query separada para buscar imagens
    categorias = CategoriaDeImagen.all.includes(:imagens)
    render json: categorias.map { |c| categoria_json(c) }
  end

  # GET /categorias_de_imagens/:id
  # Retorna uma categoria com todas as suas imagens
  def show
    # include_imagems: true → inclui a lista de imagens no JSON
    render json: categoria_json(@categoria, include_imagems: true)
  end

  # POST /categorias_de_imagens
  # Cria uma nova categoria (requer autenticação)
  def create
    categoria = CategoriaDeImagen.new(categoria_params)
    save_image(categoria) # Processa e salva a imagem (se enviada)

    if categoria.save
      # status: :created → retorna HTTP 201 (sucesso ao criar)
      render json: categoria_json(categoria), status: :created
    else
      # errors.full_messages → ["Nome não pode ficar em branco", ...]
      render json: { errors: categoria.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /categorias_de_imagens/:id
  # Atualiza uma categoria existente
  def update
    # Só processa imagem se o request incluir o campo "imagem"
    save_image(@categoria) if params[:imagem].present?

    if @categoria.update(categoria_params)
      render json: categoria_json(@categoria)
    else
      render json: { errors: @categoria.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /categorias_de_imagens/:id
  # Deleta a categoria e todos os arquivos de imagem
  def destroy
    delete_image(@categoria.imagem_caminho) # Remove o arquivo físico
    @categoria.destroy                       # Remove do banco (e imagens filhas)
    head :no_content                         # Retorna HTTP 204 (sucesso sem body)
  end

  private

  # Busca a categoria pelo ID da URL (:id)
  # rescue → se não encontrar, retorna erro 404 em vez de crashar
  def set_categoria
    @categoria = CategoriaDeImagen.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Category not found" }, status: :not_found
  end

  # Strong Parameters: lista de campos permitidos no request
  # params.permit(:nome) → só aceita o campo "nome", ignora o resto
  # Protege contra ataques de mass assignment
  def categoria_params
    params.permit(:nome)
  end

  # Salva a imagem enviada pelo usuário
  #
  # Fluxo:
  # 1. Verifica se uma imagem foi enviada (params[:imagem])
  # 2. Se já existe uma imagem antiga, deleta o arquivo anterior
  # 3. Gera um nome único para o arquivo (ex: "a1b2c3d4e5f6g7h8.webp")
  # 4. Se já for .webp, salva direto; senão, converte com MiniMagick
  # 5. Grava o nome do arquivo no campo imagem_caminho do registro
  def save_image(record)
    return unless params[:imagem].present?

    # Deleta a imagem antiga para liberar espaço
    delete_image(record.imagem_caminho) if record.imagem_caminho.present?

    uploaded = params[:imagem]

    # SecureRandom.hex(8) → gera 16 caracteres hexadecimais aleatórios
    # Isso evita colisão de nomes de arquivo
    filename = "#{SecureRandom.hex(8)}.webp"
    filepath = Rails.root.join("public", "uploads", filename)

    # Cria a pasta public/uploads/ se não existir
    FileUtils.mkdir_p(File.dirname(filepath))

    if uploaded.original_filename.end_with?(".webp")
      # Já é .webp → salva direto
      File.binwrite(filepath, uploaded.read)
    else
      # Converte para .webp usando MiniMagick (ImageProcessing gem)
      # Tempfile → arquivo temporário que será deletado após a conversão
      tmp = Tempfile.new([ "upload", File.extname(uploaded.original_filename) ])
      tmp.binmode  # Define modo binário (importante para imagens)
      tmp.write(uploaded.read)
      tmp.rewind   # Volta ao início do arquivo para ler

      # ImageProcessing::MiniMagick converte o formato
      processed = ImageProcessing::MiniMagick.source(tmp).convert("webp").call
      File.binwrite(filepath, IO.binread(processed.path))

      tmp.close
      tmp.unlink  # Deleta o arquivo temporário
    end

    # Grava o nome do arquivo no registro (será salvo no banco com .save)
    record.imagem_caminho = filename
  end

  # Deleta um arquivo de imagem do disco
  # Rails.root.join monta o caminho completo: /caminho/do/projeto/public/uploads/arquivo
  def delete_image(caminho)
    return unless caminho.present?

    path = Rails.root.join("public", "uploads", caminho)
    File.delete(path) if File.exist?(path)
  end

  # Monta o JSON de resposta para uma categoria
  # Se include_imagems: true, inclui a lista de imagens (usado no show)
  # Se false, inclui apenas a contagem (usado no index, mais leve)
  def categoria_json(categoria, include_imagems: false)
    json = {
      id: categoria.id,
      nome: categoria.nome,
      imagem_url: categoria.imagem_url,
      created_at: categoria.created_at,
      updated_at: categoria.updated_at
    }

    if include_imagems
      json[:imagens] = categoria.imagens.map { |i| imagen_json(i) }
    else
      json[:total_imagens] = categoria.imagens.count
    end

    json
  end

  # Monta o JSON de resposta para uma imagem individual
  def imagen_json(imagen)
    {
      id: imagen.id,
      nome: imagen.nome,
      descricao: imagen.descricao,
      imagem_url: imagen.imagem_url,
      created_at: imagen.created_at
    }
  end
end
