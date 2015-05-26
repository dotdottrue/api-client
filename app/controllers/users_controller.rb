class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    if @user.save
      log_in(@user)
      
      salt_masterkey = OpenSSL::Random.random_bytes 64

      iteration = 10000

      digest = OpenSSL::Digest::SHA256.new

      masterkey = OpenSSL::PKCS5.pbkdf2_hmac(user_params[:password], salt_masterkey, iteration, 256, digest)

      keys = OpenSSL::PKey::RSA.new 2048
      $PRIVKEY_USER = keys.to_pem

      cipher = OpenSSL::Cipher.new('AES-128-ECB')
      cipher.encrypt
      cipher.key = masterkey
      privkey_user_enc = cipher.update($PRIVKEY_USER) + cipher.final

      response = HTTParty.post("http://#{$SERVER_IP}/",
                :body => { :name => @user.name,
                           :salt_masterkey => stringEncoding(salt_masterkey),
                           :pubkey_user => stringEncoding(keys.public_key.to_pem),
                           :privkey_user_enc => stringEncoding(privkey_user_enc)
                          }.to_json,
                :headers => { 'Content-Type' => 'application/json'})
      redirect_to messages_url, :notice => "Willkommen #{@user.name}"
    else
      redirect_to new_user_path
    end

    # respond_to do |format|
    #   if @user.present?
    #   #add status codes etc
    #     format.html { redirect_to @user, notice: 'User was successfully created.' }
    #     format.json { render :show, status: :ok, location: @user }
    #   else
    #     #fehler beim erstellen des Users
    #     format.html { render :new }
    #     format.json { render json: @user.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
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

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
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
