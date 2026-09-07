class ColecaosController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_colecao, only: [ :show, :update, :destroy ]

  def index
    render json: Colecao.order(:ordem, :nome).map { |c| colecao_json(c) }
  end

  def show
    render json: colecao_json(@colecao)
  end

  def create
    colecao = Colecao.new(nome: colecao_params[:nome], ordem: ordem_param)
    save_image(colecao)

    if colecao.save
      render json: colecao_json(colecao), status: :created
    else
      render json: { errors: colecao.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    save_image(@colecao) if params[:imagem].present?
    @colecao.nome = colecao_params[:nome]
    @colecao.ordem = ordem_param if params[:ordem].present?

    if @colecao.save
      render json: colecao_json(@colecao)
    else
      render json: { errors: @colecao.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    delete_image(@colecao.imagem_caminho)
    @colecao.destroy
    head :no_content
  end

  private

  def set_colecao
    @colecao = Colecao.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Colecao not found" }, status: :not_found
  end

  def colecao_params
    params.permit(:nome, :ordem, :imagem)
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

  def colecao_json(colecao)
    {
      id: colecao.id,
      nome: colecao.nome,
      ordem: colecao.ordem,
      imagem_url: colecao.imagem_url,
      created_at: colecao.created_at,
      updated_at: colecao.updated_at
    }
  end
end
