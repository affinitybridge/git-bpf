#!/usr/bin/env ruby
base_path = File.dirname(__FILE__)
$LOAD_PATH.unshift(base_path) unless $LOAD_PATH.include?(base_path)

require 'commands/recreate-branch'
require 'commands/share-rerere-cache'
