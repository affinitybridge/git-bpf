#!/usr/bin/env ruby

# Pull latest conflict resolutions.
remote_name = `git config --get gitbpf.remotename`.chomp
if remote_name.empty?
  STDERR.puts "You have not configured the remote repository to be used by git-bpf. This is needed for rerere sharing. To use the 'origin' remote, run \n \`git config gitbpf.remotename 'origin'\`\n You can specify a remote name of your choosing."
  exit 1
end
`git share-rerere pull -r #{remote_name}`
