# Configures RubyLLM to use either OpenAI or AIML API based on environment variables.
# Usage:
#   For OpenAI: Set OPENAI_API_KEY
#   For AIML:   Set AIML_API_KEY (and optionally LLM_MODEL)

if defined?(RubyLLM)
  RubyLLM.configure do |config|
    if ENV['AIML_API_KEY'].present?
      # AIML API Configuration (using OpenAI adapter)
      config.openai_api_key = ENV['AIML_API_KEY']
      config.openai_api_base = 'https://api.aimlapi.com/v1'
      
      # Set default model if not specified in requests, though Controller usually handles this
      # AIML supports models like 'mistralai/Mistral-7B-v0.1'
    elsif ENV['OPENAI_API_KEY'].present?
      # Standard OpenAI Configuration
      config.openai_api_key = ENV['OPENAI_API_KEY']
    end
  end
end
