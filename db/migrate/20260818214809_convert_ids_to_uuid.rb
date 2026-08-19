class ConvertIdsToUuid < ActiveRecord::Migration[8.1]
  def up
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    remove_foreign_key :imagens, :categoria_de_imagens if foreign_key_exists?(:imagens, :categoria_de_imagens)

    drop_table :imagens if table_exists?(:imagens)
    drop_table :categoria_de_imagens if table_exists?(:categoria_de_imagens)
    drop_table :users if table_exists?(:users)
    drop_table :active_storage_variant_records if table_exists?(:active_storage_variant_records)
    drop_table :active_storage_attachments if table_exists?(:active_storage_attachments)
    drop_table :active_storage_blobs if table_exists?(:active_storage_blobs)

    create_table :active_storage_blobs do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum
      t.datetime :created_at,   null: false
      t.index    :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string     :name,       null: false
      t.text       :record_id,  null: false
      t.string     :record_type, null: false
      t.references :blob,       null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime   :created_at, null: false
      t.index      [:record_type, :record_id, :name, :blob_id], name: :index_active_storage_attachments_uniqueness, unique: true
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false
      t.index [:blob_id, :variation_digest], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
      t.datetime :created_at, null: false
    end

    create_table :users, id: :uuid do |t|
      t.string :username
      t.string :password_digest
      t.string :token
      t.boolean :admin, default: false
      t.timestamps
    end

    create_table :categoria_de_imagens, id: :uuid do |t|
      t.string :nome
      t.timestamps
    end

    create_table :imagens, id: :uuid do |t|
      t.references :categoria_de_imagens, type: :uuid, foreign_key: true
      t.string :nome
      t.string :descricao
      t.timestamps
    end
  end

  def down
    drop_table :imagens
    drop_table :categoria_de_imagens
    drop_table :users
    drop_table :active_storage_variant_records
    drop_table :active_storage_attachments
    drop_table :active_storage_blobs

    create_table :users do |t|
      t.string :username
      t.string :password_digest
      t.string :token
      t.boolean :admin, default: false
      t.timestamps
    end

    create_table :categoria_de_imagens do |t|
      t.string :nome
      t.timestamps
    end

    create_table :imagens do |t|
      t.references :categoria_de_imagens, foreign_key: true
      t.string :nome
      t.string :descricao
      t.timestamps
    end

    create_table :active_storage_blobs do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum
      t.datetime :created_at,   null: false
      t.index    :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string     :name,       null: false
      t.references :record,     null: false, polymorphic: true
      t.references :blob,       null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime   :created_at, null: false
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false
      t.index [:blob_id, :variation_digest], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
      t.datetime :created_at, null: false
    end
  end
end
