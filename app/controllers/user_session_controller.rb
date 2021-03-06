require 'openssl'
class UserSessionController < ApplicationController
  def new
  end

  def create
    @user = User.find_by(name: params[:user_session][:name].downcase)
    if @user && @user.authenticate(params[:user_session][:password])
      log_in(@user)

      response = HTTParty.get("http://#{$SERVER_IP}/#{@user.name}")

      if response.code === 200
        iteration = 10000

        digest = OpenSSL::Digest::SHA256.new

        masterkey = OpenSSL::PKCS5.pbkdf2_hmac(params[:user_session][:password], Base64.strict_decode64(response["salt_masterkey"]), iteration, 256, digest)

        $pubkey_user = OpenSSL::PKey::RSA.new(Base64.strict_decode64(response["pubkey_user"]))

        decipher = OpenSSL::Cipher::AES.new(128, :ECB)
        decipher.decrypt
        decipher.padding = 0
        decipher.key = masterkey

        privkey_user_enc_plane = Base64.strict_decode64(response["privkey_user_enc"])
        privkey_user_enc = decipher.update(privkey_user_enc_plane) + decipher.final
      
        $privkey_user = OpenSSL::PKey::RSA.new(privkey_user_enc, masterkey)

        flash[:notice] = "Statuscode: 200, Nachricht: Benutzerdaten wurden abgerufen."
        redirect_to messages_url, :notice => "Willkommen, #{@user.name}"
  	  else
        redirect_to root_url, :notice => "Nachricht: Benutzerdaten konnte nicht abgerufen werden!"
      end
    else
  		redirect_to root_url, :notice => "Benutzername oder Passwort stimmen nicht überein!"
  	end
  end

  def destroy
    log_out
  end
end
