#
# From homebrew (https://raw.github.com/mxcl/homebrew/go).
#
class Tty
  class <<self
    def blue; bold 34; end
    def white; bold 39; end
    def red; underline 31; end
    def yellow; underline 33 ; end
    def reset; escape 0; end
    def em; underline 39; end
    def green; color 92 end
    def gray; bold 30 end

    def width
      `/usr/bin/tput cols`.strip.to_i
    end

  private
    def color n
      escape "0;#{n}"
    end
    def bold n
      escape "1;#{n}"
    end
    def underline n
      escape "4;#{n}"
    end
    def escape n
      "\033[#{n}m" if $stdout.tty?
    end
  end
end

def ohai title, *sput
  title = title.to_s[0, Tty.width - 4] if $stdout.tty?
  puts "#{Tty.blue}==>#{Tty.white} #{title}#{Tty.reset}"
  puts sput unless sput.empty?
end

def oh1 title
  title = title.to_s[0, Tty.width - 4] if $stdout.tty?
  puts "#{Tty.green}==>#{Tty.white} #{title}#{Tty.reset}"
end

def opoo warning
  puts "#{Tty.red}Warning#{Tty.reset}: #{warning}"
end

def onoe error
  lines = error.to_s.split'\n'
  puts "#{Tty.red}Error#{Tty.reset}: #{lines.shift}"
  puts lines unless lines.empty?
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
    return true
  end
end
