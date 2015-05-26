class UserSessionController < ApplicationController
  def new
  end

  def create
  	@user = User.find_by(name: params[:user_session][:name].downcase)
    if @user && @user.authenticate(params[:user_session][:password])
      log_in(@user)

      response = HTTParty.get("http://#{$SERVER_IP}/#{@user.name}")

      iteration = 10000

      digest = OpenSSL::Digest::SHA256.new

      masterkey = OpenSSL::PKCS5.pbkdf2_hmac(params[:user_session][:password], stringDecoding(response["salt_masterkey"]), iteration, 256, digest)

      $pubkey_user = stringDecoding(response["pubkey_user"])

      decipher = OpenSSL::Cipher::AES.new(128, :ECB)
      decipher.decrypt
      decipher.padding = 0
      decipher.key = masterkey

      privkey_user_enc_plane = stringDecoding(response["privkey_user_enc"])
      privkey_user_enc = decipher.update(privkey_user_enc_plane) + decipher.final
    
      $privkey_user = OpenSSL::PKey::RSA.new(privkey_user_enc, masterkey)

  		redirect_to messages_url, :notice => "Willkommen, #{@user.name}"  
  	else
  		redirect_to root_url, :notice => "User name or password doesn't match!!"
  	end
  end

  def destroy
    log_out
  end
end
