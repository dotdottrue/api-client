class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include UserSessionHelper
  include MessagesHelper
  include ApplicationHelper

  helper_method :current_user

  def current_user
    User.where(id: session[:user_id]).first
  end

	def authenticate
    if !logged_in?
      redirect_to root_path
    end
  end

  def get_recipients
    response = HTTParty.get("http://#{$SERVER_IP}/")
    @recipients = []
    response.each do |recipient|
      if recipient["username"] != current_user.name
        @recipients << recipient["username"]
      end
    end
  end

  def get_messages
    timestamp = Time.now.to_i
    document = current_user.name.to_s + timestamp.to_s
    digest = OpenSSL::Digest::SHA256.new
    sig_user = $privkey_user.sign digest, document
    response = HTTParty.get("http://#{$SERVER_IP}/#{current_user.name}/message",
                  :body => {  
                              :timestamp => timestamp,
                              :sig_user => Base64.strict_encode64(sig_user),
                            }.to_json,
                  :headers => { 'Content-Type' => 'application/json'})
    
    response
  end
end
