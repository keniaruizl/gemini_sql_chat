namespace :gemini_sql_chat do
  desc "Ejecuta tareas programadas pendientes"
  task run_scheduled_tasks: :environment do
    puts "[#{Time.current}] Verificando tareas programadas..."

    tasks = GeminiSqlChat::ScheduledTask.active.due
    count = tasks.count

    if count == 0
      puts "  No hay tareas pendientes"
      next
    end

    puts "  Encontradas #{count} tarea(s) pendiente(s)"

    tasks.find_each do |task|
      puts "  Ejecutando tarea: #{task.name} (ID: #{task.id})"
      
      begin
        result = task.execute!
        if result[:success]
          puts "    ✓ Ejecutada exitosamente"
        else
          puts "    ✗ Error: #{result[:error]}"
        end
      rescue => e
        puts "    ✗ Excepción: #{e.message}"
        Rails.logger.error "Error ejecutando tarea programada #{task.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    puts "[#{Time.current}] Proceso completado"
  end

  desc "Inicia el scheduler en modo continuo (para desarrollo)"
  task scheduler: :environment do
    require 'rufus-scheduler'
    
    puts "Iniciando scheduler de Gemini SQL Chat..."
    puts "Presiona Ctrl+C para detener"
    
    scheduler = Rufus::Scheduler.new
    
    # Ejecutar cada minuto
    scheduler.every '1m' do
      Rake::Task['gemini_sql_chat:run_scheduled_tasks'].invoke
    end
    
    # Mantener el proceso vivo
    scheduler.join
  end
end
