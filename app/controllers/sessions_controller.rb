class SessionsController < ApplicationController
  skip_before_action :authenticate, only: :create
  before_action :set_session, only: %i[ show destroy ]

  def index
    render json: Current.user.sessions.order(created_at: :desc)
  end

  def show
    render json: @session
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      @session = user.sessions.create!
      response.set_header "X-Session-Token", @session.signed_id

      user_json = UserSerializer.new(user).serializable_hash[:data][:attributes].to_json
      render json: user_json, status: :created
    else
      render json: { error: "That email or password is incorrect" }, status: :unauthorized
    end
  end

  def destroy
    @session.destroy
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
