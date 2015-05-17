class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include UserSessionHelper
  include ApplicationHelper

	def authenticate
    if !logged_in?
      redirect_to root_path
    end
  end

  def stringEncoding(input)
    new_string = Base64.encode64(input).encode('utf-8')
    return new_string
  end
end
