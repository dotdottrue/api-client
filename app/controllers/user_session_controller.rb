class UserSessionController < ApplicationController
  def login
  end

  def create
  	@user = User.find_by(name: params[:user_session][:name].downcase)
  	if @user && @user.authenticate(params[:user_session][:password])
  		log_in(@user)
      #response = HTTParty.get("#{Webclient::Application::WEBSERVICE_URL}"/"#{@user.name}")

      # iteration = 10000

      # digest = OpenSSL::Digest::SHA256.new

      # masterkey = OpenSSL::PKCS5.pbkdf2_hmac(params[:user_session][:password], stringDencoding(response["salt_masterkey"]), iteration, 256, digest)


  		redirect_to messages_url, notice: 'Logged in!'
  	else
  		flash[:notice] = 'Username/Password or both are wrong!'
  		render 'login'
  	end
  end

  def destroy
    log_out
    redirect_to root_url, notice: "Logged out!"
  end
end
