#!/usr/bin/env ruby

my_path = File.dirname(__FILE__)
 
# This script requires the git library in the Ruby library path.
tools_lib = File.expand_path(File.join(my_path, '.', 'lib'))
$LOAD_PATH.unshift(tools_lib) unless $LOAD_PATH.include?(tools_lib)

require 'gitflow'
require 'git-helpers'

module ShareReReReMixin
  def options(opts)
    opts.git_dir = '.git'
    opts.rr_cache_dir = '.git/rr-cache'
    opts.branch = 'rr-cache'
    opts.remote = 'origin'

    [
      ['-g', '--git-dir DIR',
        "The name of your git dir, defaults to #{opts.git_dir}.",
        lambda { |n| opts.git_dir = n }],
      ['-c', '--cache_dir DIR',
        "The location of your rr-cache dir, defaults to #{opts.rr_cache_dir}.",
        lambda { |n| opts.rr_cache_dir = n }],
      ['-b', '--branch NAME',
        "The name of the branch your rr-cache is stored in, defaults to #{opts.branch}.",
        lambda { |n| opts.branch = n }],
      ['-r', '--remote NAME',
        "The name of the remote to use when getting the latest rr-cache, defaults to #{opts.remote}.",
        lambda { |r| opts.remote = r }],
    ]
  end
end

#
# share-rerere: Recreate a branch based on the merge commits it's comprised of.
#
class ShareReReRe < GitFlow/'share-rerere'

  @documentation = <<-HELP
A collection of commands to help share your rr-cache.

Available commands:
 - push
 - pull
  HELP

  def execute(opts, argv)
    run('share-rerere', '--help')
  end


  class PushReReRe < ShareReReRe/'push'

    @help = "Push your latest conflict resolutions."

    include GitHelpersMixin
    include ShareReReReMixin

    def execute(opts, argv)
      if not branchExists? opts.branch
        puts "Couldn't find branch #{opts.branch}."
        throw :exit
      end

      current = git("rev-parse", "--abbrev-ref", "HEAD")
      params = [
        "--git-dir=#{opts.git_dir}",
        "--work-tree=#{opts.rr_cache_dir}"
      ]

      git("checkout", opts.branch)

      git(*(params + ["add", "-A"]))

      begin
        git(*(params + ["commit", "-m", "new resolutions"]))
        git("push", opts.remote, opts.branch)
      rescue

      end

      git("checkout", current)
    end
  end

  class PullReReRe < ShareReReRe/'pull'

    @help = "Pull the latest conflict resolutions."

    include GitHelpersMixin
    include ShareReReReMixin

    def execute(opts, argv)
      current = git("rev-parse", "--abbrev-ref", "HEAD")
      params = [
        "--git-dir=#{opts.git_dir}",
        "--work-tree=#{opts.rr_cache_dir}"
      ]

      git("fetch", opts.remote)

      if not branchExists? opts.branch
        git("branch", opts.branch, "#{opts.remote}/#{opts.branch}")
      end

      git(*(params + ["checkout", opts.branch, "--", "."]))
    end
  end
end
