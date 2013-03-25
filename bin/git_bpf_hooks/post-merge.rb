#!/usr/bin/env ruby

parents = `git rev-list -n 1 --parents HEAD`.split("\s")

# Shift off the last commit.
last = parents.shift

if parents.length >= 2
  `git share-rerere pull`
  `git share-rerere push`
end
