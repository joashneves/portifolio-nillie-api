class SketchbooksController < ApplicationController
  # index e show são públicos (sketchbook visível sem login)
  skip_before_action :authenticate_user!, only: [ :index, :show ]

  before_action :set_sketchbook, only: [ :show, :update, :destroy ]

  # GET /sketchbooks
  def index
    render json: Sketchbook.order(:ordem, :nome).map { |s| sketchbook_json(s) }
  end

  # GET /sketchbooks/:id
  def show
    render json: sketchbook_json(@sketchbook, include_imagems: true)
  end

  # POST /sketchbooks
  def create
    sketchbook = Sketchbook.new(nome: sketchbook_params[:nome], ordem: ordem_param)
    save_image(sketchbook)

    if sketchbook.save
      render json: sketchbook_json(sketchbook), status: :created
    else
      render json: { errors: sketchbook.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /sketchbooks/:id
  def update
    save_image(@sketchbook) if params[:imagem].present?
    @sketchbook.nome = sketchbook_params[:nome]
    @sketchbook.ordem = ordem_param if params[:ordem].present?

    if @sketchbook.save
      render json: sketchbook_json(@sketchbook)
    else
      render json: { errors: @sketchbook.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /sketchbooks/:id
  def destroy
    delete_image(@sketchbook.imagem_caminho)
    @sketchbook.destroy
    head :no_content
  end

  private

  def set_sketchbook
    @sketchbook = Sketchbook.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Sketchbook not found" }, status: :not_found
  end

  def sketchbook_params
    params.permit(:nome)
  end

  def ordem_param
    return if params[:ordem].blank?

    Integer(params[:ordem])
  rescue ArgumentError, TypeError
    nil
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

  def sketchbook_json(sketchbook, include_imagems: false)
    json = {
      id: sketchbook.id,
      nome: sketchbook.nome,
      ordem: sketchbook.ordem,
      imagem_url: sketchbook.imagem_url,
      created_at: sketchbook.created_at,
      updated_at: sketchbook.updated_at
    }

    if include_imagems
      json[:imagens] = sketchbook.imagens_de_sketchbooks.map { |i| imagem_json(i) }
    else
      json[:total_imagens] = sketchbook.imagens_de_sketchbooks.count
    end

    json
  end

  def imagem_json(imagem)
    {
      id: imagem.id,
      nome: imagem.nome,
      descricao: imagem.descricao,
      imagem_url: imagem.imagem_url,
      created_at: imagem.created_at,
      updated_at: imagem.updated_at
    }
  end
end