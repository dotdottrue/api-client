require 'crypto_messenger/message'

class MessagesController < ApplicationController
  before_action :set_message, only: [:show, :edit, :update, :destroy]

  # def message_overview
  #   @sended_messages = Message.find_by_sender(current_user.name)
  #   puts "Test"
  #   puts @sended_messages.to_json
  # end

  # GET /messages
  # GET /messages.json
  def index
    @user_messages = Message.where(sender: current_user.name)

    @messages = get_messages

    if @messages.code === 200
      @messages.each do |message|
        message["cipher"] = CryptoMessenger::Message.decrypt(message)

        new_message = Inbox.new(recipient: message["sender"], message: message["cipher"])
        new_message.save

        puts "#####################################################"
        puts message["cipher"]
        puts "#####################################################"
      end

      @inbox = Inbox.where(recipient: current_user.name)

      flash[:notice] = "Statuscode:200 Nachricht: OK"
    elsif @messages.code === 503
      flash[:notice] = "Statuscode: 503, Nachricht: Falsche Signatur"
    elsif @messages.code === 501
      flash[:notice] = "Statuscode: 501, Nachricht: Anfragezeit zu lang."
    end
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
  end

  # GET /messages/new
  def new
    get_recipients
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit
  end

  # POST /messages
  # POST /messages.json
  def create
    @message = Message.new(message_params)

    encrypt = CryptoMessenger::Message.encrypt(@message, current_user)

    # if encrypt.code === 200
    #   flash[:notice] = "Statuscode: 200, Nachricht: Nachricht wurde erfolreich an den Server gesendet."
    # elsif encrypt.code === 503
    #   flash[:notice] = "Statuscode: 503, Nachricht: Der Dienst ist grade nicht erreichbar."
    # elsif encrypt.code === 500
    #   flash[:notice] = "Statuscode: 500, Nachricht: Interner Serverfehler."
    # end
      respond_to do |format|
        if @message.save
          format.html { redirect_to @message, notice: 'Nachricht wurde erfolgreich angelegt.' }
        else
          format.html { render :new }
          flash[:notice] = "Nachricht wurde nicht erfolgreich erstellt."
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
