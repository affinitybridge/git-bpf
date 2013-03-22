#
# From homebrew (https://raw.github.com/mxcl/homebrew/go).
#
module Tty extend self
  def blue; bold 34; end
  def white; bold 39; end
  def red; underline 31; end
  def reset; escape 0; end
  def bold n; escape "1;#{n}" end
  def underline n; escape "4;#{n}" end
  def escape n; "\033[#{n}m" if STDOUT.tty? end

  def ohai *args
    puts "#{blue}==>#{white} #{args.shell_s}#{reset}"
  end

  def warn warning
    puts "#{red}Warning#{reset}: #{warning.chomp}"
  end
end

class Array
  def shell_s
    cp = dup
    first = cp.shift
    cp.map{ |arg| arg.gsub " ", "\\ " }.unshift(first) * " "
  end

  def shell_list
    cp = dup
    dup.map{ |val| " - #{val}" }.join("\n")
  end
end

class String
  def undent
    gsub(/^.{#{slice(/^ +/).length}}/, '')
  end
end

module GitHelpersMixin
  def context(work_tree, git_dir, *args)
    # Git pull requires absolute paths when executed from outside of the
    # repository's work tree.
    params = [
      "--git-dir=#{File.expand_path(git_dir)}",
      "--work-tree=#{File.expand_path(work_tree)}"
    ]
    return params + args
  end

  def branchExists?(branch)
    ref = (branch.include? "refs/heads/") ? branch : "refs/heads/#{branch}"
    begin
      git('show-ref', '--verify', '--quiet', ref)
    rescue
      return false
    end
    return true
  end

  def refExists?(ref)
    begin
      git('show-ref', '--tags', '--heads', ref)
    rescue
      return false
    end
    return true
  end

  def terminate(message = nil)
    puts message if message != nil
    throw :exit
  end

  def promptYN(message)
    puts
    puts "#{message} [y/N]"
    unless STDIN.gets.chomp == 'y'
      return false
    end
    puts "\n"
    return true
  end
end

class Repository
  include GitHelpersMixin
  include GitFlow::Mixin

  attr_accessor :ctx, :remote_name, :remote_url, :path, :git_dir

  def initialize(path)
    path = File.expand_path(path)
    git_dir = File.join(path, '.git')

    if not File.directory? git_dir
      terminate "#{path} is not a git repository."
    end

    self.git_dir = git_dir
    self.path = path
    self.ctx = context(self.path, self.git_dir)
  end

  def remoteUrl(name)
    begin
      config(false, "--get", "remote.#{name}.url")
    rescue
      terminate "No remote named '#{name}' in repository: #{self.path}."
    end
  end

  def cmd(*args)
    git(*self.ctx, *args)
  end

  def config(local?, *args)
    return nil if args.empty?

    command = ["config"]
    command.push "--local" if local?
    command += args

    cmd(*self.ctx, *command)
  end

  def self.clone(url, dest)
    git('clone', url, dest)
    Repository.new dest
  end

  def self.init(dir, *args)
    ctx = context(dir, File.join(dir, '.git'))
    command = ['init'] + args
    git(*ctx, *command)
    Repository.new dir
  end
end
