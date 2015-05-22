module UserSessionHelper

  #user log in
  def log_in(user)
    session[:user_id] = user.id

    response = HTTParty.get("http://#{Webclient::Application::WEBSERVICE_URL}/#{user.name}")

    iteration = 10000

    digest = OpenSSL::Digest::SHA256.new

    masterkey = OpenSSL::PKCS5.pbkdf2_hmac(user_params[:password], stringDecoding(response["salt_masterkey"]), iteration, 256, digest)

    $pubkey_user = stringDecoding(response["pubkey_user"])

    decipher = OpenSSL::Cipher.new('AES-128-ECB')
    decipher.decrypt
    decipher.key = masterkey
    $privkey_user = cipher.update(stringDecoding(response["privkey_user_enc"])) + decipher.final
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