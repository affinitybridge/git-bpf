#!/usr/bin/env ruby

parents = `git rev-list -n 1 --parents HEAD`.split("\s")

# Shift off the last commit.
last = parents.shift

if parents.length >= 2
  remote_name = `git config --get gitbpf.remotename`.chomp
  `git share-rerere pull -r #{remote_name}`
  `git share-rerere push -r #{remote_name}`
end
