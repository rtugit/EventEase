module Api
  class AiImagesController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!, raise: false

    def create
      prompt = params[:prompt]

      if prompt.blank?
        return render json: { error: "Prompt is required" }, status: :unprocessable_entity
      end

      begin
        client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

        response = client.images.generate(
          parameters: {
            model: "dall-e-3",
            prompt: prompt,
            size: "1024x1024",
            quality: "standard",
            n: 1
          }
        )

        image_url = response.dig("data", 0, "url")

        if image_url
          render json: { image_url: image_url }
        else
          render json: { error: "Failed to generate image" }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "AI Image Error: #{e.message}"
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
