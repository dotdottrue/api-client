class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user
  include UserSessionHelper
  include ApplicationHelper

  def current_user
    @current_user ||= User.find_by(id: user_session[:user_id])
  end

	def authenticate
    if !logged_in?
      redirect_to root_path
    end
  end

  def stringEncoding(input)
    new_string = Base64.strict_encode64(input)
    return new_string
  end

  def stringDencoding(input)
    new_string = Base64.strict_encode64(input)
    return new_string
  end
end
