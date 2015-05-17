class UserSessionController < ApplicationController
  def login
  end

  def create
  	user = User.find_by(name: params[:user_session][:name].downcase)
  	if user && user.authenticate(params[:user_session][:password])
  		log_in(user)
  		redirect_to messages_url, notice: 'Logged in!'
  	else
  		flash[:notice] = 'Username/Password or both are wrong!'
  		render 'login'
  	end
  end

  def log_out
  	user_session[:user_id] = nil
  	redirect_to root_path, notice: "Logged out!"
  end
end
