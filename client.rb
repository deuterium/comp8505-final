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

## Variables

$KEY = OpenSSL::Digest::SHA256.new("verysecretkey").digest

## Functions

## Application Strings
CONFIG_FILE = "client.conf"
CONFIG_FILE_DEFAULT << "\# pen_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# pen_port = 8668\n"
CONFIG_FILE_DEFAULT << "\# exfil_prot = tcp\n"
CONFIG_FILE_DEFAULT << "\# exfil_port = 6886\n"
CONFIG_FILE_DEFAULT << "\# interface = eth1\n"
CONFIG_EDIT = "Please edit #{CONFIG_FILE} and relaunch."
CONFIG_CREATE = "Configuration file created. #{CONFIG_EDIT}"
CONFIG_INVALID = "Error parsing configuration. #{CONFIG_EDIT}"

## Main
