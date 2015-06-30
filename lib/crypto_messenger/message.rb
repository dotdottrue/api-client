module CryptoMessenger
  class Message

    def self.create_pubkey_recipient(recipient, key_recipient)
      
      pub_key = get_pubkey(recipient)

      key_recipient_enc = pub_key.public_encrypt key_recipient

      key_recipient_enc
    end

    def self.create_sig_recipient(current_user_name, encrypted_message, iv, key_recipient_enc)
      @digest = OpenSSL::Digest::SHA256.new
    
      @document = current_user_name + encrypted_message + iv + key_recipient_enc

      sig_recipient = $privkey_user.sign @digest, @document

      sig_recipient
    end

    def self.create_sig_service(current_user_name, encrypted_message, iv, key_recipient_enc, timestamp, message_recipient)
      outter_signature =  current_user_name + encrypted_message + iv + key_recipient_enc + timestamp + message_recipient

      sig_service = $privkey_user.sign @digest, outter_signature

      sig_service
    end

    def self.send_message(sender, encrypted_message, iv, key_recipient_enc, sig_recipient, timestamp, recipient, sig_service)
      response = HTTParty.post("http://#{$SERVER_IP}/#{recipient}/message",
                :body => { :outerMessage => { :timestamp => timestamp, 
                          :sig_service => Base64.strict_encode64(sig_service),
                          :sender => sender, 
                          :cipher => Base64.strict_encode64(encrypted_message),
                          :iv => Base64.strict_encode64(iv),
                          :key_recipient_enc => Base64.strict_encode64(key_recipient_enc),
                          :sig_recipient => Base64.strict_encode64(sig_recipient)
                        }                           
                          }.to_json,
                :headers => { 'Content-Type' => 'application/json'})

      response
    end

    def self.sig_recipient_check(message)
      digest = OpenSSL::Digest::SHA256.new
      
      pub_key = get_pubkey(message["sender"])

      document = message["sender"].to_s + Base64.strict_decode64(message["cipher"]).to_s + Base64.strict_decode64(message["iv"]).to_s + Base64.strict_decode64(message["key_recipient_enc"]).to_s
      check_sig = pub_key.verify digest, Base64.strict_decode64(message["sig_recipient"]), document

      check_sig
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

    def self.get_pubkey(name)
      pubkey_response = HTTParty.get("http://#{$SERVER_IP}/#{name}/pubkey")

      pubkey_recipient = Base64.strict_decode64(pubkey_response["pubkey_user"])
      pub_key = OpenSSL::PKey::RSA.new(pubkey_recipient)

      pub_key
    end

  end
end
