module CryptoMessenger
  class Message
    
    def self.encrypt(plain_message, current_user)
      enrycpted_message = CryptoMessenger::Message.encrypt_message(plain_message)

      key_recipient_enc = CryptoMessenger::Message.create_pubkey_recipient(plain_message.recipient)

      timestamp = Time.now.to_i     

      sig_recipient = CryptoMessenger::Message.create_sig_recipient(current_user.name.to_s, @encrypted_message.to_s, @key_recipient_enc.to_s, @iv.to_s)

      sig_service = CryptoMessenger::Message.create_sig_service(timestamp.to_s, plain_message.recipient.to_s, @document.to_s)

      response = CryptoMessenger::Message.send_message(plain_message.sender, @encrypted_message, key_recipient_enc, sig_recipient, timestamp, plain_message.recipient, sig_service)
    end

    def self.encrypt_message(plain_message)
      cipher = OpenSSL::Cipher.new('AES-128-CBC')
      cipher.encrypt
      @key_recipient = cipher.random_key
      @iv = cipher.random_iv

      @encrypted_message = cipher.update(plain_message.message) + cipher.final

      @encrypted_message
    end

    def self.create_pubkey_recipient(recipient)
      pubkey_response = HTTParty.get("http://#{$SERVER_IP}/#{recipient}/pubkey")
      pubkey_recipient = Base64.strict_decode64(pubkey_response["pubkey_user"])
      pub_key = OpenSSL::PKey::RSA.new(pubkey_recipient)

      key_recipient_enc = pub_key.public_encrypt @key_recipient

      key_recipient_enc
    end

    def self.create_sig_recipient(current_user_name, encrypted_message, key_recipient_enc, iv)
      @digest = OpenSSL::Digest::SHA256.new
    
      @document = current_user_name + encrypted_message + iv + key_recipient_enc

      sig_recipient = $privkey_user.sign @digest, @document

      sig_recipient
    end

    def self.create_sig_service(timestamp, message_recipient, document)
      outter_signature =  document + timestamp + message_recipient

      sig_service = $privkey_user.sign @digest, outter_signature

      sig_service
    end

    def self.send_message(sender, encrypted_message, key_recipient_enc,sig_recipient, timestamp, recipient, sig_service)
      response = HTTParty.post("http://#{$SERVER_IP}/message",
                :body => {  :sender => sender,
                            :cipher => Base64.strict_encode64(encrypted_message),
                            :iv => Base64.strict_encode64(@iv),
                            :key_recipient_enc => Base64.strict_encode64(key_recipient_enc),
                            :sig_recipient => Base64.strict_encode64(sig_recipient),
                            :timestamp => timestamp,
                            :recipient => recipient,
                            :sig_service => Base64.strict_encode64(sig_service)
                          }.to_json,
                :headers => { 'Content-Type' => 'application/json'})

      response
    end

    def self.decrypt(message)
      key_recipient = $privkey_user.private_decrypt Base64.strict_decode64(message["key_recipient_enc"])
      iv = Base64.strict_decode64(message["iv"])
      cipher = OpenSSL::Cipher.new('AES-128-CBC')
      decipher = cipher.decrypt
      decipher.key = key_recipient
      decipher.iv = iv
      plain_message = decipher.update(Base64.strict_decode64(message["cipher"])) + decipher.final

      plain_message
    end

  end
end
