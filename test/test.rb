#!/usr/bin/env ruby

require 'lib/gitflow'
require 'lib/git-helpers'

#
# test: Recreate a branch based on the merge commits it's comprised of.
#
class Test < GitFlow/'test'

  include GitHelpersMixin
  include ShareReReReMixin

  def options(opts)
  end

  def execute(opts, argv)
    setup

    teardown
  end

  def setup
    createBareRepo "remote"
  end

  def teardown
    sh('rm', '-r', '-f', "remote")
  end

  def createBareRepo(name)
    remote = Repo.new(expand_path(name))
    sh(remote.path
    git(remote.context + ['init', '--bare'])
  end

  class Repo
    def initialize(path, bare = false)
      @path = path
    end

    def context
      [
        "--git-dir=#{@path}/.git",
        "--work-tree=#{@path}"
      ]
    end
  end
end

