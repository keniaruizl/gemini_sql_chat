# Gemini SQL Chat Engine

Un motor de Rails que proporciona un chatbot inteligente con capacidades de generación de SQL utilizando Google Gemini. Permite a los usuarios consultar su base de datos utilizando lenguaje natural.

## Características

*   **Conversión de Lenguaje Natural a SQL**: Transforma preguntas en español a consultas SQL ejecutables.
*   **Descubrimiento Automático de Esquema**: Detecta tablsa y relaciones automáticamente para dar contexto a la IA.
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

### Layout
El motor hereda del `ApplicationController` de tu aplicación principal y utiliza el `layout "default"` por defecto.

Si tu aplicación utiliza otro layout (por ejemplo `application`), puedes crear un initializer en `config/initializers/gemini_chat.rb` para configurarlo:

```ruby
# config/initializers/gemini_chat.rb
GeminiSqlChat::ChatController.layout "application"
```

### Modelos de Usuario
El motor asume que existe un modelo `User` y un método `current_user` (como el que proporciona Devise).

## Uso

Navega a `/gemini_chat` en tu navegador para interactuar con el asistente.

## Licencia

[MIT](MIT-LICENSE)
