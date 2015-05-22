class UserSessionController < ApplicationController
  def new
  end

  def create
  	@user = User.find_by(name: params[:user_session][:name].downcase)
  	if @user && @user.authenticate(params[:user_session][:password])
      log_in(@user)

      response = HTTParty.get("http://#{Webclient::Application::WEBSERVICE_URL}/#{user.name}")

      iteration = 10000

      digest = OpenSSL::Digest::SHA256.new

      masterkey = OpenSSL::PKCS5.pbkdf2_hmac(user_params[:password], stringDecoding(response["salt_masterkey"]), iteration, 256, digest)

      $pubkey_user = stringDecoding(response["pubkey_user"])

      decipher = OpenSSL::Cipher.new('AES-128-ECB')
      decipher.decrypt
      decipher.key = masterkey
      $privkey_user = cipher.update(stringDecoding(response["privkey_user_enc"])) + decipher.final
  
  		redirect_to messages_url, :notice => "Willkommen, #{@user.name}"  
  	else
  		redirect_to root_url, :notice => "User name or password doesn't match!!"
  	end
  end

  def destroy
    log_out
  end
end
