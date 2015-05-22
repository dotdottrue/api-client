module UserSessionHelper

  #user log in
  def log_in(user)
    session[:user_id] = user.id
  end

  #check if user is logged_in
  def logged_in?
    !current_user.nil?
  end

  def log_out
    session[:user_id] = nil
    @current_user = nil
    redirect_to ''
  end
end