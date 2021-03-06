require 'crypto_messenger/message'

class MessagesController < ApplicationController
  before_action :set_message, only: [:show, :edit, :update, :destroy]

  def index
    @user_messages = Message.where(sender: current_user.name)
    @messages = get_messages

    if @messages.code === 200
      @messages.each do |message|
        puts "#####################################################"
        puts "###################SIGNATURE CHECK###################"
        puts "#####################################################"
        if CryptoMessenger::Message.sig_recipient_check(message)
          puts "###################SIGNATURE Valid###################"
          puts "#####################################################"
          message["cipher"] = CryptoMessenger::Message.decrypt(message)

          new_message = Inbox.new(sender: message["sender"], message: message["cipher"], recipient: message["recipient"])
          new_message.save

          puts "#####################################################"
          puts message["cipher"]
          puts "#####################################################"
        else
          puts "##################SIGNATURe invalid##################"
          puts "#####################################################"
          flash[:notice] = "Die Signaturen stimmen nicht überein!"
        end
      end

      @inbox = Inbox.where(recipient: current_user.name).order(created_at: :desc)
      flash[:notice] = "Statuscode:200 Nachricht: OK"
    elsif @messages.code === 503
      flash[:notice] = "Statuscode: 503, Nachricht: Falsche Signatur"
    elsif @messages.code === 501
      flash[:notice] = "Statuscode: 501, Nachricht: Anfragezeit zu lang."
    end
  end

  def show
  end

  def new
    get_recipients
    @message = Message.new
  end

  def edit
  end

  def create
    @message = Message.new(message_params)

    cipher = OpenSSL::Cipher.new('AES-128-CBC')
    cipher.encrypt
    @key_recipient = cipher.random_key
    @iv = cipher.random_iv

    timestamp = Time.now.to_i  

    encrypted_message = cipher.update(@message.message) + cipher.final

    key_recipient_enc = CryptoMessenger::Message.create_pubkey_recipient(@message.recipient, @key_recipient)

    sig_recipient = CryptoMessenger::Message.create_sig_recipient(current_user.name.to_s, encrypted_message.to_s, @iv.to_s, key_recipient_enc.to_s)
    
    sig_service = CryptoMessenger::Message.create_sig_service( current_user.name.to_s, encrypted_message.to_s, @iv.to_s, key_recipient_enc.to_s, sig_recipient.to_s, timestamp.to_s, @message.recipient.to_s)

    response = CryptoMessenger::Message.send_message(current_user.name, encrypted_message, @iv, key_recipient_enc, sig_recipient, timestamp, @message.recipient, sig_service)
    
      respond_to do |format|
        if response.code === 200
          flash[:notice] = "Statuscode: 200, Nachricht: Nachricht wurde erfolreich an den Server gesendet."
          if @message.save
            format.html { redirect_to @message, notice: 'Nachricht wurde erfolgreich angelegt.' }
          else
            format.html { render :new }
            flash[:notice] = "Nachricht wurde nicht erfolgreich erstellt."
          end
        elsif response.code === 503
          flash[:notice] = "Statuscode: 503, Nachricht: Der Dienst ist grade nicht erreichbar."
        elsif response.code === 500
          flash[:notice] = "Statuscode: 500, Nachricht: Interner Serverfehler."
        end
      end

  end

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
