require_relative "lib/gemini_sql_chat/version"

Gem::Specification.new do |spec|
  spec.name        = "gemini_sql_chat"
  spec.version     = GeminiSqlChat::VERSION
  spec.authors     = ["sergioviss"]
  spec.email       = ["sergio@cuatropuntocero.solutions"]
  spec.homepage    = "https://example.com"
  spec.summary     = "Gemini SQL Chatbot Engine"
  spec.description = "A Rails engine for SQL-based chatbot using Google Gemini."

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/example/gemini_sql_chat"
  spec.metadata["changelog_uri"] = "https://github.com/example/gemini_sql_chat/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.5.1"
  spec.add_dependency "httparty"
  spec.add_dependency "rufus-scheduler"
end
