class UserSessionController < ApplicationController
  def new
  end

  def create
  	@user = User.find_by(name: params[:user_session][:name].downcase)
  	if @user && @user.authenticate(params[:user_session][:password])
      log_in(@user)

  		redirect_to messages_url, :notice => "Willkommen, #{@user.name}"  
  	else
  		redirect_to root_url, :notice => "User name or password doesn't match!!"
  	end
  end

  def destroy
    log_out
  end
end
