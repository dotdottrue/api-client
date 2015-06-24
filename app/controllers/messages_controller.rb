class MessagesController < ApplicationController
  before_action :set_message, only: [:show, :edit, :update, :destroy]

  
  def message_overview
    @sended_messages = Message.find_by_sender(current_user.name)
    puts "Test"
    puts @sended_messages.to_json
  end
  # GET /messages
  # GET /messages.json
  def index
    @messages = getMessages

    if !@message.nil?
      puts "testen wir mal den scheiß"
      puts @messages
      puts "testen den shit ende"
      @messages.each do |m|
        key_recipient = $privkey_user.private_decrypt stringDecoding(m["key_recipient_enc"])
        iv = stringDecoding(m["iv"])
        cipher = OpenSSL::Cipher.new('AES-128-CBC')
        decipher = cipher.decrypt
        decipher.key = key_recipient
        decipher.iv = iv
        plain_message = decipher.update(stringDecoding(m["cipher"])) + decipher.final
        m["cipher"] = plain_message
        puts "#####################################################"
        puts plain_message
        puts "#####################################################"
      end
    end
    if response.status === 200
      flash[:notice] = "200 ist ausgabe"
    elsif response.status === 503
      flash[:notice] = "503 Wrong Signature"
    end
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
  end

  # GET /messages/new
  def new
    getRecipients
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit
  end

  # POST /messages
  # POST /messages.json
  def create
    @message = Message.new(message_params)

    response = HTTParty.get("http://#{$SERVER_IP}/#{@message.recipient}/pubkey")
    pubkey_recipient = stringDecoding(response["pubkey_user"])

    cipher = OpenSSL::Cipher.new('AES-128-CBC')
    cipher.encrypt
    key_recipient = cipher.random_key
    iv = cipher.random_iv

    encrypted_message = cipher.update(@message.message) + cipher.final

    pub_key = OpenSSL::PKey::RSA.new(pubkey_recipient)

    key_recipient_enc = pub_key.public_encrypt key_recipient

    timestamp = Time.now.to_i

    digest = OpenSSL::Digest::SHA256.new
    
    document = current_user.name.to_s + encrypted_message.to_s + iv.to_s + key_recipient_enc.to_s

    sig_recipient = $privkey_user.sign digest, document

    outterSignature = document.to_s + timestamp.to_s + @message.recipient.to_s

    sig_service = $privkey_user.sign digest, outterSignature

    response = HTTParty.post("http://#{$SERVER_IP}/message",
                :body => {  :sender => @message.sender,
                            :cipher => stringEncoding(encrypted_message),
                            :iv => stringEncoding(iv),
                            :key_recipient_enc => stringEncoding(key_recipient_enc),
                            :sig_recipient => stringEncoding(sig_recipient),
                            :timestamp => timestamp,
                            :recipient => @message.recipient,
                            :sig_service => stringEncoding(sig_service)
                          }.to_json,
                :headers => { 'Content-Type' => 'application/json'})

    respond_to do |format|
      if @message.save
        format.html { redirect_to @message, notice: 'Message was successfully created.' }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /messages/1
  # PATCH/PUT /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to @message, notice: 'Message was successfully updated.' }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Message.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_params
      params.require(:message).permit(:sender, :message, :recipient)
    end
end
