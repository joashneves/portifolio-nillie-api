class ImagensDeSketchbooksController < ApplicationController
  # index e show são públicos (sketchbook visível sem login)
  skip_before_action :authenticate_user!, only: [ :index, :show ]

  # Sempre carrega o sketchbook pai antes de qualquer action
  before_action :set_sketchbook

  # Carrega a imagem individual para show, update e destroy
  before_action :set_imagem, only: [ :show, :update, :destroy ]

  # GET /sketchbooks/:sketchbook_id/imagens_de_sketchbooks
  def index
    imagens = @sketchbook.imagens_de_sketchbooks
    render json: imagens.map { |i| imagem_json(i) }
  end

  # GET /sketchbooks/:sketchbook_id/imagens_de_sketchbooks/:id
  def show
    render json: imagem_json(@imagem)
  end

  # POST /sketchbooks/:sketchbook_id/imagens_de_sketchbooks
  def create
    imagem = @sketchbook.imagens_de_sketchbooks.new(imagem_params)
    save_image(imagem)

    if imagem.save
      render json: imagem_json(imagem), status: :created
    else
      render json: { errors: imagem.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /sketchbooks/:sketchbook_id/imagens_de_sketchbooks/:id
  def update
    save_image(@imagem) if params[:imagem].present?

    if @imagem.update(imagem_params)
      render json: imagem_json(@imagem)
    else
      render json: { errors: @imagem.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /sketchbooks/:sketchbook_id/imagens_de_sketchbooks/:id
  def destroy
    delete_image(@imagem.imagem_caminho)
    @imagem.destroy
    head :no_content
  end

  private

  def set_sketchbook
    @sketchbook = Sketchbook.find(params[:sketchbook_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Sketchbook not found" }, status: :not_found
  end

  def set_imagem
    @imagem = @sketchbook.imagens_de_sketchbooks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Image not found" }, status: :not_found
  end

  def imagem_params
    params.permit(:nome, :descricao)
  end

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

  def delete_image(caminho)
    return unless caminho.present?

    path = Rails.root.join("public", "uploads", caminho)
    File.delete(path) if File.exist?(path)
  end

  def imagem_json(imagem)
    {
      id: imagem.id,
      nome: imagem.nome,
      descricao: imagem.descricao,
      imagem_url: imagem.imagem_url,
      sketchbook_id: imagem.sketchbook_id,
      created_at: imagem.created_at,
      updated_at: imagem.updated_at
    }
  end
end