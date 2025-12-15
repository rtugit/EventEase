class AccountsController < ApplicationController
  def show
  end

  def personal_info
    # Personal info edit page
  end

  def update
    if current_user.update(user_params)
      redirect_to account_path, notice: "Profile updated successfully!"
    else
      render :personal_info, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :gender, :photo)
  end

  def update
    if handle_photo_upload && current_user.update(user_params)
      redirect_to personal_info_path, notice: "Profile updated successfully!"
    else
      render :personal_info, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :gender)
  end

  def handle_photo_upload
    photo_data = params[:user][:photo_data]
    return true if photo_data.blank?

    if photo_data.start_with?('data:image')
      begin
        encoded_data = photo_data.split(',')[1]
        decoded_data = Base64.decode64(encoded_data)

        current_user.photo.attach(
          io: StringIO.new(decoded_data),
          filename: "avatar_#{current_user.id}_#{Time.current.to_i}.jpg",
          content_type: 'image/jpeg'
        )
        true
      rescue => e
        Rails.logger.error("Photo upload error: #{e.message}")
        false
      end
    else
      true
    end
  end
end
