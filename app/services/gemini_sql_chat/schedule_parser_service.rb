module GeminiSqlChat
  class ScheduleParserService
    # Patrones para detectar comandos de programación
    SCHEDULE_PATTERNS = [
      # Intervalos en minutos
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+minuto/i,
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+min/i,
      # Intervalos en horas
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+hora/i,
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+hr/i,
      # Intervalos en segundos
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+segundo/i,
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+seg/i,
      # Intervalos en días
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+día/i,
      /(?:cada|repite|ejecuta|haz)\s+(\d+)\s+dia/i,
      # Diario
      /(?:diario|diariamente|todos los días)/i,
      # Horario específico
      /(?:a las|a la)\s+(\d{1,2}):(\d{2})/i,
    ].freeze

    def self.parse_schedule_command(text)
      return nil unless text.present?

      normalized_text = text.downcase.strip

      # Buscar patrones de programación
      SCHEDULE_PATTERNS.each do |pattern|
        match = normalized_text.match(pattern)
        next unless match

        # Extraer la pregunta sin el comando de programación
        question = remove_schedule_commands(text)

        if normalized_text.match?(/minuto|min/i)
          minutes = match[1].to_i
          return {
            has_schedule: true,
            question: question,
            schedule_type: 'interval',
            interval_seconds: minutes * 60,
            schedule_text: "cada #{minutes} minuto#{minutes > 1 ? 's' : ''}"
          }
        elsif normalized_text.match?(/hora|hr/i)
          hours = match[1].to_i
          return {
            has_schedule: true,
            question: question,
            schedule_type: 'interval',
            interval_seconds: hours * 3600,
            schedule_text: "cada #{hours} hora#{hours > 1 ? 's' : ''}"
          }
        elsif normalized_text.match?(/segundo|seg/i)
          seconds = match[1].to_i
          return {
            has_schedule: true,
            question: question,
            schedule_type: 'interval',
            interval_seconds: seconds,
            schedule_text: "cada #{seconds} segundo#{seconds > 1 ? 's' : ''}"
          }
        elsif normalized_text.match?(/día|dia/i)
          days = match[1].to_i
          return {
            has_schedule: true,
            question: question,
            schedule_type: 'interval',
            interval_seconds: days * 86400,
            schedule_text: "cada #{days} día#{days > 1 ? 's' : ''}"
          }
        elsif normalized_text.match?(/diario|diariamente|todos los días/i)
          return {
            has_schedule: true,
            question: question,
            schedule_type: 'interval',
            interval_seconds: 86400, # 24 horas
            schedule_text: "diariamente"
          }
        elsif normalized_text.match?(/a las|a la/i)
          hour = match[1].to_i
          minute = match[2].to_i
          # Calcular segundos hasta la próxima hora
          now = Time.current
          target_time = Time.new(now.year, now.month, now.day, hour, minute, 0)
          target_time += 1.day if target_time < now
          interval_seconds = (target_time - now).to_i
          
          return {
            has_schedule: true,
            question: question,
            schedule_type: 'interval',
            interval_seconds: interval_seconds,
            schedule_text: "a las #{hour}:#{minute.to_s.rjust(2, '0')}"
          }
        end
      end

      nil
    end

    def self.remove_schedule_commands(text)
      # Remover comandos de programación del texto
      cleaned = text.dup
      
      # Remover patrones comunes
      cleaned.gsub!(/(?:cada|repite|ejecuta|haz)\s+\d+\s+(?:minuto|min|hora|hr|segundo|seg|día|dia)/i, '')
      cleaned.gsub!(/(?:diario|diariamente|todos los días)/i, '')
      cleaned.gsub!(/(?:a las|a la)\s+\d{1,2}:\d{2}/i, '')
      
      cleaned.strip
    end

    def self.has_schedule_command?(text)
      parse_schedule_command(text).present?
    end
  end
end
