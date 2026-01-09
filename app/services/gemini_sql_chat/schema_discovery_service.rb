module GeminiSqlChat
  class SchemaDiscoveryService
  # Columnas que NUNCA queremos enviar a la IA por seguridad
  IGNORED_COLUMNS = %w[encrypted_password reset_password_token confirmation_token unlock_token]
  
  # Tablas internas de Rails o gemas que no aportan valor al negocio
  IGNORED_MODELS = %w[SchemaMigration ActiveRecord::InternalMetadata ActiveStorage::Attachment ActiveStorage::Blob ApplicationRecord]

  def self.discover_schema
    # Importante: Forzar la carga de modelos en modo desarrollo
    Rails.application.eager_load! unless Rails.configuration.eager_load

    schema_text = "TABLAS Y ESTRUCTURA DETECTADA AUTOMÁTICAMENTE:\n\n"
    
    # 1. Obtener modelos válidos
    models = ::ActiveRecord::Base.descendants.reject do |model|
      model.abstract_class? || 
      IGNORED_MODELS.include?(model.name) ||
      !model.table_exists?
    end

    # 2. Describir Tablas y Columnas
    models.each_with_index do |model, index|
      columns = model.columns.reject { |c| IGNORED_COLUMNS.include?(c.name) }
      col_names = columns.map(&:name).join(', ')
      
      schema_text += "#{index + 1}. #{model.table_name} (#{col_names})\n"
    end

    schema_text += "\nRELACIONES:\n"

    # 3. Describir Relaciones (Clave para los JOINs)
    models.each do |model|
      model.reflect_on_all_associations.each do |assoc|
        # Solo listamos si la asociación apunta a otro modelo conocido
        # y evitamos redundancia (ej. solo mostramos has_many, no los belongs_to inversos si no queremos saturar)
        if assoc.macro == :has_many || assoc.macro == :has_one
           schema_text += "- #{model.table_name} -> #{assoc.name} (relación 1:N o 1:1)\n"
        end
      end
    end
    
    schema_text
  end
  end
end
