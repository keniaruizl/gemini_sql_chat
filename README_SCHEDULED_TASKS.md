# Tareas Programadas - Gemini SQL Chat

## Funcionalidad

El sistema ahora permite programar consultas SQL para que se ejecuten automáticamente en intervalos regulares. Puedes decirle al asistente cosas como:

- "Cada 5 minutos, ¿cuántas ventas hay hoy?"
- "Repite cada hora, ¿cuál es el total de pedidos pendientes?"
- "Ejecuta cada 30 minutos, ¿cuántos usuarios nuevos hay?"

## Comandos Soportados

El sistema detecta automáticamente comandos de programación en lenguaje natural:

### Intervalos
- **Minutos**: "cada 5 minutos", "repite cada 10 min"
- **Horas**: "cada 2 horas", "ejecuta cada hora"
- **Segundos**: "cada 30 segundos" (útil para pruebas)
- **Días**: "cada día", "diariamente"

### Ejemplos de Uso

```
Usuario: "Cada 5 minutos, ¿cuántas ventas hay hoy?"
Asistente: ✅ Tarea programada creada - Se ejecutará cada 5 minutos
```

```
Usuario: "Repite cada hora, ¿cuál es el total de pedidos pendientes?"
Asistente: ✅ Tarea programada creada - Se ejecutará cada 1 hora
```

## Gestión de Tareas

### Ver Tareas Programadas

Haz clic en el botón "Tareas" en el header del chat para ver todas tus tareas programadas activas.

### Eliminar Tareas

Desde el modal de tareas programadas, puedes eliminar cualquier tarea haciendo clic en el icono de eliminar.

## Ejecución Automática

Las tareas se ejecutan automáticamente mediante un proceso de scheduler. Para activarlo:

### Opción 1: Rake Task Manual (Desarrollo)
```bash
rails gemini_sql_chat:run_scheduled_tasks
```

### Opción 2: Scheduler Continuo (Desarrollo)
```bash
rails gemini_sql_chat:scheduler
```

### Opción 3: Cron Job (Producción)

Agrega a tu crontab para ejecutar cada minuto:
```bash
* * * * * cd /ruta/a/tu/app && bin/rails gemini_sql_chat:run_scheduled_tasks RAILS_ENV=production
```

O usando `whenever` gem:
```ruby
# config/schedule.rb
every 1.minute do
  rake "gemini_sql_chat:run_scheduled_tasks"
end
```

## Características

- ✅ Detección automática de comandos de programación
- ✅ Ejecución inmediata al crear la tarea
- ✅ Historial de ejecuciones
- ✅ Manejo de errores
- ✅ Interfaz visual para gestionar tareas
- ✅ Resultados guardados en la conversación asociada

## Modelo de Datos

Las tareas programadas se almacenan en la tabla `gemini_sql_chat_scheduled_tasks` con:
- Nombre y pregunta
- Tipo de programación (intervalo o cron)
- Próxima ejecución
- Contador de ejecuciones
- Último resultado y error

## Seguridad

- Solo el usuario propietario puede ver/eliminar sus tareas
- Las tareas respetan las mismas validaciones de seguridad que las consultas normales (solo SELECT)
- Las tareas se ejecutan con el contexto del usuario que las creó
