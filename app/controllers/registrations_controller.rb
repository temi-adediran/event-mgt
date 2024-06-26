class RegistrationsController < ApplicationController
  skip_before_action :authenticate

  def create
    @user = User.new(user_params)

    if @user.save
      set_session_in_header(@user)
      send_email_verification
      user_json = UserSerializer.new(@user).serializable_hash[:data][:attributes].to_json
      render json: user_json, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.permit(:email, :password, :password_confirmation)
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
