class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

      salt_masterkey = OpenSSL::Random.random_bytes 64

      iteration = 10000

      digest = OpenSSL::Digest::SHA256.new

      masterkey = OpenSSL::PKCS5.pbkdf2_hmac(user_params[:password], salt_masterkey, iteration, 256, digest)

      keys = OpenSSL::PKey::RSA.new 2048
      $privkey_user = keys.to_pem

      cipher = OpenSSL::Cipher.new('AES-128-ECB')
      cipher.encrypt
      cipher.key = masterkey
      privkey_user_enc = cipher.update($privkey_user) + cipher.final

      response = HTTParty.post("http://#{$SERVER_IP}/",
                :body => { :name => @user.name,
                           :salt_masterkey => Base64.strict_encode64(salt_masterkey),
                           :pubkey_user => Base64.strict_encode64(keys.public_key.to_pem),
                           :privkey_user_enc => Base64.strict_encode64(privkey_user_enc)
                          }.to_json,
                :headers => { 'Content-Type' => 'application/json'})

    if response.code === 200 
      @user.save
      flash[:notice] = "Statuscode: 200, Nachricht: Benutzer wurde erfolgreich Registriert"
      redirect_to ''
    elsif response.code === 501 
      flash[:notice] = "Statuscode: 501, Nachricht: Benutzer existiert bereits."
      redirect_to new_user_path
    elsif response.code === 500
      flash[:notice] = "Statuscode: 500, Nachricht: Interner Serverfehler."
      redirect_to new_user_path
    else
      flash[:notice] = "Benutzer konnte nicht angelegt werden."
      redirect_to new_user_path
    end
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    response = HTTParty.get("http://#{$SERVER_IP}/#{current_user.name}/delete")
    @user = User.find(current_user.id)
    #if response.code === 200
    if Message.where(sender: @user.name).exists?
      Message.where(sender: @user.name).destroy_all
      if Inbox.where(recipient: @user.name).exists?
        Inbox.where(recipient: @user.name).destroy_all
      end
      current_user = nil
    end
    @user.destroy
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Benutzer wurde gelöscht.' }
      format.json { head :no_content }
    end
    # else
    #   redirect_to messages_url, :notice => "Aufgrund eines serverinternen Fehlers konnte der Benutzer nicht gelöscht werden."
    # end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :password)
    end
end
