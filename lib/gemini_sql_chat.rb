require "gemini_sql_chat/version"
require "gemini_sql_chat/engine"
require "httparty"

module GeminiSqlChat
  mattr_accessor :additional_context

  def self.setup
    yield self
  end
end
