module GeminiSqlChat
  class ScheduledTask < ApplicationRecord
    self.table_name = 'gemini_sql_chat_scheduled_tasks'

    acts_as_paranoid

    belongs_to :user
    belongs_to :conversation, class_name: 'GeminiSqlChat::Conversation', foreign_key: 'gemini_sql_chat_conversation_id', optional: true

    validates :name, presence: true
    validates :question, presence: true
    validates :schedule_type, presence: true, inclusion: { in: %w[interval cron] }
    validates :next_run_at, presence: true
    validate :schedule_validation

    scope :active, -> { where(active: true) }
    scope :due, -> { where('next_run_at <= ?', Time.current) }
    scope :for_user, ->(user_id) { where(user_id: user_id) }

    def schedule_validation
      if schedule_type == 'interval'
        errors.add(:interval_seconds, 'es requerido para schedule_type interval') if interval_seconds.blank? || interval_seconds <= 0
      elsif schedule_type == 'cron'
        errors.add(:cron_expression, 'es requerido para schedule_type cron') if cron_expression.blank?
      end
    end

    def calculate_next_run
      if schedule_type == 'interval'
        self.next_run_at = Time.current + interval_seconds.seconds
      elsif schedule_type == 'cron'
        # Para simplificar, usaremos interval también para cron básico
        # En producción podrías usar la gema 'fugit' para parsear cron
        # Por ahora, si hay interval_seconds, lo usamos
        if interval_seconds.present?
          self.next_run_at = Time.current + interval_seconds.seconds
        else
          # Fallback: 1 hora
          self.next_run_at = Time.current + 1.hour
        end
      end
    end

    def execute!
      return unless active?

      self.last_run_at = Time.current
      self.run_count += 1

      begin
        gemini_service = GeminiSqlChat::GeminiService.new
        conversation_history = conversation&.conversation_history || []
        result = gemini_service.generate_sql(question, conversation_history)

        # Guardar resultado
        result_summary = if result[:type] == :sql_result
          "Ejecutado: #{result[:summary]} (#{result[:results].length} resultados)"
        else
          "Respuesta: #{result[:text]}"
        end

        self.last_result = result_summary
        self.last_error = nil

        # Guardar mensaje en conversación si existe
        if conversation
          conversation.messages.create!(
            role: 'assistant',
            content: result[:type] == :sql_result ? result[:summary] : result[:text],
            sql_query: result[:sql],
            results_count: result[:results]&.length || 0,
            results_data: result[:results] || [],
            suggested_questions: result[:suggested_questions] || []
          )
        end

        calculate_next_run
        save!

        { success: true, result: result_summary }
      rescue => e
        self.last_error = e.message
        calculate_next_run
        save!

        Rails.logger.error "Error ejecutando tarea programada #{id}: #{e.message}"
        { success: false, error: e.message }
      end
    end

    def human_readable_schedule
      if schedule_type == 'interval'
        if interval_seconds < 60
          "cada #{interval_seconds} segundo#{interval_seconds > 1 ? 's' : ''}"
        elsif interval_seconds < 3600
          minutes = interval_seconds / 60
          "cada #{minutes} minuto#{minutes > 1 ? 's' : ''}"
        elsif interval_seconds < 86400
          hours = interval_seconds / 3600
          "cada #{hours} hora#{hours > 1 ? 's' : ''}"
        else
          days = interval_seconds / 86400
          "cada #{days} día#{days > 1 ? 's' : ''}"
        end
      else
        cron_expression || 'cron'
      end
    end
  end
end
