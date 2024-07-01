class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :set_current_request_details
  before_action :authenticate

  private
    def authenticate
      if session_record = authenticate_with_http_token { |token, _| Session.find_signed(token) }
        Current.session = session_record
      else
        request_http_token_authentication
      end
    end

    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end

    def require_lock(wait: 1.hour, attempts: 10)
      counter = Kredis.counter("require_lock:#{request.remote_ip}:#{controller_path}:#{action_name}", expires_in: wait)
      counter.increment

      if counter.value > attempts
        render json: { error: "You've exceeded the maximum number of attempts" }, status: :too_many_requests
      end
    end

    def set_session_in_header(user)
      session = user.sessions.create!
      response.set_header "X-Session-Token", session.signed_id
    end
end
