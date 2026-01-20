# Gemini SQL Chat Engine

Un motor de Rails que proporciona un chatbot inteligente con capacidades de generación de SQL utilizando Google Gemini. Permite a los usuarios consultar su base de datos utilizando lenguaje natural.

## Características

*   **Conversión de Lenguaje Natural a SQL**: Transforma preguntas en español a consultas SQL ejecutables.
*   **Descubrimiento Automático de Esquema**: Detecta tablas y relaciones automáticamente para dar contexto a la IA.
*   **Tareas Programadas**: Programa consultas para ejecutarse automáticamente en intervalos regulares (ej: "cada 5 minutos").
*   **Seguridad**: Solo permite consultas `SELECT` y bloquea comandos peligrosos.
*   **Interfaz Lista para Usar**: Incluye una interfaz de chat moderna y responsiva.
*   **Historial de Conversaciones**: Guarda el historial de mensajes por usuario.

## Requisitos

*   Ruby on Rails 7.0+
*   PostgreSQL
*   Una API Key de Google Gemini

## Instalación

1.  Agrega la gema a tu `Gemfile`. Puedes apuntar directamente al repositorio de GitHub:

    ```ruby
    gem 'gemini_sql_chat', git: 'git@github.com:Cuatro-Punto-Cero-MX/gemini_sql_chat.git'
    ```

    O si la tienes localmente para desarrollo:

    ```ruby
    gem 'gemini_sql_chat', path: 'ruta/a/gemini_sql_chat'
    ```

2.  Ejecuta `bundle install`.

3.  Monta el motor en tu archivo `config/routes.rb`:

    ```ruby
    mount GeminiSqlChat::Engine => "/gemini_chat"
    ```

4.  Instala y corre las migraciones:

    ```bash
    rails gemini_sql_chat:install:migrations
    rails db:migrate
    ```

5.  Configura tu API Key de Google Gemini. Asegúrate de tener la variable de entorno configurada en tu proyecto principal:

    ```bash
    export GOOGLE_GEMINI_API_KEY='tu_api_key_aqui'
    ```

    O usando `dotenv`, agrégala a tu `.env`.

## Configuración y Personalización


## Configuración y Personalización

Para configurar el motor, se recomienda crear un archivo initializer en tu aplicación, por ejemplo `config/initializers/gemini_sql_chat.rb`.

### 1. Configurar Layout
Por defecto, el motor usa el layout `"default"`. Si tu aplicación usa `application.html.erb` u otro, configúralo así:

```ruby
# config/initializers/gemini_sql_chat.rb
GeminiSqlChat::ChatController.layout "application"
```

### 2. Contexto de Negocio Personalizado (Custom Context)
Puedes inyectar reglas de negocio específicas que ayudarán a la IA a entender mejor tu base de datos y evitar alucinaciones.

#### Ejemplo Básico (Texto Estático)
Útil para definiciones constantes del negocio.

```ruby
GeminiSqlChat.setup do |config|
  config.additional_context = <<~TEXT
    REGLAS DE NEGOCIO:
    1. La tabla 'users' contiene tanto empleados como clientes. Los empleados tienen role='admin' o 'vendedor'.
    2. Las ventas solo se consideran válidas si estado_venta_id = 5 (Completada).
    3. Ignora la tabla 'tmp_importaciones'.
  TEXT
end
```

#### Ejemplo Avanzado (Contexto Dinámico)
Útil si necesitas que el contexto cambie según el usuario actual, la fecha, o el environment.

```ruby
GeminiSqlChat.setup do |config|
  config.additional_context = -> { 
    # Este bloque se ejecuta en cada petición
    user = Current.user
    role_info = user.admin? ? "El usuario es Administrador total." : "El usuario es un Vendedor de la sucursal #{user.sucursal_id}."
    
    <<~CONTEXT
      FECHA ACTUAL: #{Date.today}
      USUARIO ACTUAL: #{user.name} (#{user.email})
      PERMISOS: #{role_info}
      
      NOTA: Si el usuario pregunta por "mis ventas", filtra por user_id = #{user.id}.
    CONTEXT
  }
end
```

### Modelos de Usuario
El motor asume que existe un modelo `User` y un método `current_user` (como el que proporciona Devise).

## Uso

Navega a `/gemini_chat` en tu navegador para interactuar con el asistente.

### Tareas Programadas

Puedes programar consultas automáticas usando comandos como:
- "Cada 5 minutos, ¿cuántas ventas hay hoy?"
- "Repite cada hora, ¿cuál es el total de pedidos pendientes?"

Ver [README_SCHEDULED_TASKS.md](README_SCHEDULED_TASKS.md) para más detalles sobre tareas programadas.

### Configurar el Scheduler

Para que las tareas programadas se ejecuten automáticamente, necesitas configurar el scheduler:

**Desarrollo:**
```bash
rails gemini_sql_chat:scheduler
```

**Producción (Cron):**
```bash
# Agregar a crontab - ejecutar cada minuto
* * * * * cd /ruta/a/tu/app && bin/rails gemini_sql_chat:run_scheduled_tasks RAILS_ENV=production
```

## Licencia

[MIT](MIT-LICENSE)
