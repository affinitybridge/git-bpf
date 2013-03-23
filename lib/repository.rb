require 'lib/gitflow'
require 'lib/git-helpers'

#
#
#
class Repository
  extend GitFlow::Mixin

  include GitHelpersMixin

  attr_accessor :ctx, :remote_name, :path, :git_dir

  def initialize(path)
    path = File.expand_path(path)
    git_dir = File.join(path, '.git')

    if not File.directory? git_dir
      terminate "#{path} is not a git repository."
    end

    self.git_dir = git_dir
    self.path = path
    self.ctx = [
      "--git-dir=#{File.expand_path(git_dir)}",
      "--work-tree=#{File.expand_path(path)}"
    ]

  end

  def fetch(remote)
    self.cmd("fetch", "--quiet", remote)
  end

  def remoteUrl(name)
    begin
      config(false, "--get", "remote.#{name}.url").chomp
    rescue
      terminate "No remote named '#{name}' in repository: #{self.path}."
    end
  end

  def cmd(*args)
    self.class.git(*(self.ctx + args))
  end

  def config(local, *args)
    return nil if args.empty?

    command = ["config"]
    command.push "--local" if local
    command += args

    cmd(*(self.ctx + command))
  end

  def head
    begin
      cmd("rev-parse", "--quiet", "--abbrev-ref", "--verify", "HEAD")
    rescue
      return ''
    end
  end

  def ref?(ref)
    begin
      cmd('show-ref', '--tags', '--heads', ref)
    rescue
      return false
    end
    return true
  end

  def branch?(branch, remote = nil)
    if remote != nil
      ref = "refs/remotes/#{remote}/#{branch}"
    else
      ref = (branch.include? "refs/heads/") ? branch : "refs/heads/#{branch}"
    end

    begin
      cmd('show-ref', '--verify', '--quiet', ref)
    rescue
      return false
    end
    return true
  end

  def self.clone(url, dest)
    git('clone', url, dest)
    Repository.new dest
  end

  def self.init(dir, *args)
    ctx = [
      "--git-dir=#{File.join(dir, '.git')}",
      "--work-tree=#{dir}",
    ]
    command = ['init'] + args
    git(*(ctx + command))
    Repository.new dir
  end
end

