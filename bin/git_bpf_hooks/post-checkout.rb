#!/usr/bin/env ruby

puts "POST-CHECKOUT.rb"
# Pull latest conflict resolutions.
`git share-rerere pull`
