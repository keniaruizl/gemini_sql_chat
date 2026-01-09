module GeminiSqlChat
  class GeminiService
  include HTTParty

  base_uri 'https://generativelanguage.googleapis.com'

  def initialize
    @api_key = ENV['GOOGLE_GEMINI_API_KEY']
    raise 'GOOGLE_GEMINI_API_KEY no está configurada' if @api_key.blank?
  end

  def generate_sql(user_question, conversation_history = [])
    return nil if user_question.blank?

    # Limitar longitud de pregunta
    user_question = user_question.strip[0..500]

    # Validar si la pregunta contiene comandos SQL peligrosos
    if contains_dangerous_sql?(user_question)
      Rails.logger.warn "Pregunta bloqueada por contener comandos SQL peligrosos: #{user_question}"
      raise 'La pregunta contiene comandos SQL no permitidos. Solo se permiten consultas de lectura (SELECT).'
    end

    prompt = build_prompt(user_question, conversation_history)

    Rails.logger.info "Generando SQL para pregunta: #{user_question}"
    Rails.logger.debug "Contexto conversacional: #{conversation_history.length} mensajes" if conversation_history.any?

    response = self.class.post(
      "/v1beta/models/gemini-2.0-flash-exp:generateContent",
      query: { key: @api_key },
      headers: { 'Content-Type' => 'application/json' },
      body: {
        contents: [{
          parts: [{
            text: prompt
          }]
        }],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 800
        },
        safetySettings: [
          {
            category: "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold: "BLOCK_NONE"
          }
        ]
      }.to_json,
      timeout: 10
    )

    if response.success?
      extract_sql_from_response(response)
    else
      Rails.logger.error "Error en API de Gemini: #{response.code} - #{response.message}"
      raise "Error en API de Gemini: #{response.code} - #{response.message}"
    end
  rescue => e
    Rails.logger.error "Error generando SQL: #{e.message}"
    raise e
  end

  def execute_query(sql)
    # Validar que sea solo SELECT
    normalized_sql = sql.strip.downcase

    unless normalized_sql.start_with?('select')
      raise 'Solo se permiten queries SELECT'
    end

    # Validar palabras clave peligrosas (usando word boundaries para no bloquear 'deleted_at')
    dangerous_keywords = ['drop', 'delete', 'update', 'insert', 'alter', 'truncate', 'create', 'grant', 'revoke']
    dangerous_keywords.each do |keyword|
      if normalized_sql.match?(/\b#{keyword}\b/)
        raise "Query contiene palabra clave no permitida: #{keyword}"
      end
    end

    # Agregar LIMIT si no está presente
    unless normalized_sql.include?('limit')
      sql = "#{sql.strip.chomp(';')} LIMIT 100"
    end

    # Ejecutar query con timeout
    results = ActiveRecord::Base.connection.execute(sql).to_a

    results
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error "Error ejecutando SQL: #{e.message}"
    raise "Error en la consulta SQL: #{e.message}"
  rescue => e
    Rails.logger.error "Error inesperado: #{e.message}"
    raise e
  end

  private

  def build_prompt(user_question, conversation_history = [])
    schema_context = get_schema_context
    history_context = build_history_context(conversation_history)
    additional_context = get_additional_context

    <<~PROMPT
      Eres un experto en SQL para PostgreSQL. Tu tarea es convertir preguntas en lenguaje natural a queries SQL y sugerir preguntas de seguimiento relevantes.

      BASE DE DATOS: #{Rails.application.class.module_parent_name} (Detectada automáticamente)

      #{schema_context}

      #{history_context}

      REGLAS IMPORTANTES PARA SQL:
      1. SOLO genera queries SELECT
      2. SIEMPRE incluye LIMIT 100 al final (a menos que se especifique otro límite)
      3. Usa JOINs apropiados para relacionar tablas
      4. Para fechas, usa el formato 'YYYY-MM-DD'
      5. Usa alias descriptivos para las columnas (ej. `u` para `users`)
      6. No uses punto y coma al final
      7. ⚠️ MUY IMPORTANTE: SIEMPRE agrega "AND tabla.deleted_at IS NULL" para las tablas marcadas con [SOFT DELETE]. Si NO tiene la marca, NO lo agregues.
      8. Si la pregunta hace referencia a resultados anteriores, usa el contexto conversacional para entender la consulta
      9. ⚠️ CRÍTICO: USA SOLO LAS COLUMNAS LISTADAS EN EL ESQUEMA. No inventes columnas (ej. no asumas `name` si solo existe `email` o `first_name`). Si no estás seguro, usa `SELECT *`.

      REGLAS IMPORTANTES PARA PREGUNTAS SUGERIDAS:
      1. Genera 2-3 preguntas de seguimiento relevantes y útiles basadas en el contexto
      2. Las preguntas deben ser naturales y específicas al dominio de la base de datos
      3. Considera el historial conversacional para hacer sugerencias coherentes

      CONTEXTO ADICIONAL Y REGLAS DE NEGOCIO PROPIAS DEL PROYECTO:
      #{additional_context}

      FORMATO DE RESPUESTA:
      Debes responder ÚNICAMENTE con un objeto JSON válido con la siguiente estructura:
      {
        "sql": "tu query SQL aquí",
        "suggested_questions": [
          "Primera pregunta sugerida",
          ...
        ]
      }

      EJEMPLO GENÉRICO DE RESPUESTA JSON (Solo referencia de formato):
      {
        "sql": "SELECT u.email, COUNT(o.id) FROM users u JOIN orders o ON u.id = o.user_id WHERE u.deleted_at IS NULL GROUP BY u.email LIMIT 100",
        "suggested_questions": ["¿Qué usuario tiene más ordenes?"]
      }

      Pregunta del usuario: #{user_question}
      Respuesta JSON:
    PROMPT
  end

  def build_history_context(conversation_history)
    return "" if conversation_history.empty?

    # Tomar solo los últimos 4 mensajes (2 intercambios) para no saturar el prompt
    recent_history = conversation_history.last(4)

    context = "CONTEXTO CONVERSACIONAL:\n"
    recent_history.each do |msg|
      # Soportar tanto símbolos como strings como keys
      role = msg[:role] || msg['role']
      content = msg[:content] || msg['content']
      sql_query = msg[:sql_query] || msg['sql_query']

      if role == 'user' && content.present?
        context += "Usuario: \"#{content}\"\n"
      elsif role == 'assistant' && sql_query.present?
        # Limitar longitud del SQL en el contexto para no saturar el prompt (máximo 150 caracteres)
        sql_preview = sql_query.length > 150 ? "#{sql_query[0..150]}..." : sql_query
        context += "SQL: #{sql_preview}\n"
      end
    end
    context += "\n"

    Rails.logger.debug "Contexto conversacional construido: #{context[0..300]}..."

    context
  end

  def get_schema_context
    SchemaDiscoveryService.discover_schema
  end

  def extract_sql_from_response(response)
    begin
      # Verificar si hay candidatos en la respuesta
      candidates = response.dig('candidates')

      if candidates.blank? || candidates.empty?
        Rails.logger.error "No hay candidatos en la respuesta de Gemini"
        Rails.logger.error "Response completo: #{response.inspect}"

        # Revisar si hubo un bloqueo por seguridad
        if response.dig('promptFeedback', 'blockReason').present?
          block_reason = response.dig('promptFeedback', 'blockReason')
          Rails.logger.warn "Prompt bloqueado por Gemini: #{block_reason}"
          raise "La consulta fue bloqueada por razones de seguridad: #{block_reason}"
        end

        raise 'No se recibió ninguna respuesta válida de Gemini'
      end

      # Extraer el contenido del primer candidato
      content = response.dig('candidates', 0, 'content', 'parts', 0, 'text')

      if content.blank?
        # Verificar finish_reason para entender por qué está vacío
        finish_reason = response.dig('candidates', 0, 'finishReason')

        Rails.logger.warn "Contenido vacío en respuesta de Gemini. finishReason: #{finish_reason}"

        case finish_reason
        when 'SAFETY'
          raise 'La consulta fue bloqueada por razones de seguridad. Solo se permiten consultas de lectura (SELECT).'
        when 'RECITATION'
          raise 'La consulta fue bloqueada por contener contenido protegido por derechos de autor.'
        when 'MAX_TOKENS'
          raise 'La respuesta excedió el límite de tokens. Intenta con una pregunta más específica.'
        else
          raise 'No se pudo generar SQL desde la respuesta de Gemini'
        end
      end

      # Limpiar el contenido de posibles markdown o formato
      cleaned_content = content.strip
      cleaned_content = cleaned_content.gsub(/```json\n?/, '').gsub(/```\n?/, '')
      cleaned_content = cleaned_content.strip

      # Intentar parsear como JSON
      begin
        parsed_response = JSON.parse(cleaned_content)

        if parsed_response.is_a?(Hash) && parsed_response['sql'].present?
          sql = parsed_response['sql'].strip
          sql = sql.gsub(/;$/, '').strip

          suggested_questions = parsed_response['suggested_questions'] || []

          Rails.logger.info "SQL generado exitosamente: #{sql[0..100]}..."
          Rails.logger.info "Preguntas sugeridas: #{suggested_questions.length}"

          return { sql: sql, suggested_questions: suggested_questions }
        else
          Rails.logger.warn "JSON parseado pero no tiene la estructura esperada"
          raise "Estructura JSON inválida en la respuesta"
        end
      rescue JSON::ParserError => e
        # Fallback: Si no es JSON válido, intentar extraer SQL del texto plano (compatibilidad con respuestas antiguas)
        Rails.logger.warn "No se pudo parsear JSON, intentando extraer SQL del texto plano: #{e.message}"

        sql = cleaned_content.strip
        sql = sql.gsub(/^sql:/i, '').strip
        sql = sql.gsub(/;$/, '').strip

        Rails.logger.info "SQL extraído (modo fallback): #{sql[0..100]}..."

        return { sql: sql, suggested_questions: [] }
      end
    rescue => e
      Rails.logger.error "Error extrayendo SQL: #{e.message}"
      Rails.logger.error "Response: #{response.inspect}"
      raise e.message.include?('bloqueada') ? e : "No se pudo procesar la respuesta de Gemini: #{e.message}"
    end
  end

  def contains_dangerous_sql?(text)
    # Detectar comandos SQL peligrosos en lenguaje natural o SQL directo
    dangerous_patterns = [
      /\b(delete|drop|truncate|alter|update|insert|create|grant|revoke)\b/i,
      /\bfrom\s+(delete|drop|truncate|alter|update|insert|create)\b/i,
      /\b(elimina|borra|destruye|modifica|actualiza|inserta|crea)\s+(tabla|base|datos|registro)/i
    ]

    dangerous_patterns.any? { |pattern| text.match?(pattern) }
  end

  def get_additional_context
    context = GeminiSqlChat.additional_context
    return "" if context.blank?

    context.is_a?(Proc) ? context.call : context
  end
  end
end
