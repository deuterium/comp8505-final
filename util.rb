$KEY = OpenSSL::Digest::SHA256.new("verysecretkey").digest

def exit_reason(reason)
    puts reason
    exit
end

def load_config_file
  if File.exists? CONFIG_FILE
    validate_config
  else
    create_default_config
  end 
end

def create_default_config
  File.open(CONFIG_FILE, 'a') do |f|
      f.write(CONFIG_FILE_DEFAULT)
  end
  exit_reason(CONFIG_CREATE)
end

def valid_protocol(protocol)
  protocol.downcase!
  case protocol
  when "tcp"
    return true
  when "udp"
    return true
  else
    return false
  end
end

# Checks port range validity (1-65535)
#
# @param [Integer] num
# - port to check
# @return [bool]
# - true if valid, false if not
def valid_port(num)
    if num >= 1 && num <= 65535
      return true
    else
      return false
    end
end

def encrypt(msg)
  cipher = OpenSSL::Cipher::AES256.new(:CBC)
  cipher.encrypt

  cipher.key = $KEY

  begin
      payload = cipher.update(msg)
      payload << cipher.final
  rescue Exception => e
      puts "encryption error"
  end
  return payload
end

def decrypt(payload)
  cipher = OpenSSL::Cipher::AES256.new(:CBC)
  cipher.decrypt

  cipher.key = $KEY

  begin
      msg = cipher.update(payload)
      msg << cipher.final
  rescue Exception => e
      puts "decryption error"
  end
  return msg
end