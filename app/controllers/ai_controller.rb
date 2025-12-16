class AiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[chat generate_content]

  # POST /ai/chat
  def chat
    user_message = params[:message]
    system_prompt = build_system_prompt(params[:options] || [])

    response = RubyLLM.chat(messages: [{ role: 'system', content: system_prompt },
                                       { role: 'user', content: user_message }])

    active_response = response[:choices]&.first&.dig(:message, :content) || "I'm not sure how to respond to that."

    render_success(active_response, :message)
  rescue StandardError => e
    handle_error(e, "AI Chat Error", "I'm currently offline (API Error). Please try again later.")
  end

  # POST /ai/generate_content
  def generate_content
    prompt = params[:prompt]
    existing_text = params[:existing_text]
    action = params[:action]

    full_prompt = build_content_prompt(prompt, existing_text, action)

    response = RubyLLM.complete(prompt: full_prompt, max_tokens: 500)
    content = response[:choices]&.first&.dig(:text) || response[:choices]&.first&.dig(:message, :content)

    render_success(content.to_s.strip, :content)
  rescue StandardError => e
    handle_error(e, "AI Content Generation Error", "Unable to generate content. Please try again.")
  end

  private

  def build_system_prompt(context_options)
    prompt = "You are Eventes, a helpful AI assistant for an event management platform. " \
             "Help the user with queries about creating events, selling tickets, and managing accounts. " \
             "Be concise and friendly."

    return prompt if context_options.empty?

    "#{prompt} The user is interested in: #{context_options.join(', ').humanize}."
  end

  def build_content_prompt(prompt, existing_text, action)
    if action == 'enhance'
      "Improve the following event description to be more engaging and professional:\n\n#{existing_text}"
    else
      "Write a compelling event description for: #{prompt}"
    end
  end

  def render_success(data, key)
    render json: { key => data, status: 'success' }
  end

  def handle_error(error, log_message, user_message)
    Rails.logger.error("#{log_message}: #{error.message}")
    render json: {
      (log_message.include?('Chat') ? :message : :content) => user_message,
      status: 'error'
    }, status: :unprocessable_content
  end
end
