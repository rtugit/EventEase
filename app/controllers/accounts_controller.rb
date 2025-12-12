class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def personal_info
    # Personal info edit page
  end

  def update
    if current_user.update(user_params)
      redirect_to account_path, notice: "Profile updated successfully!"
    else
      render :personal_info, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone_number, :gender, :photo)
  end
end
