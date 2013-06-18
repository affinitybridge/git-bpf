#!/usr/bin/env ruby

# Pull latest conflict resolutions.
remote_name = `git config --get gitbpf.remotename`.chomp
`git share-rerere pull -r #{remote_name}`
