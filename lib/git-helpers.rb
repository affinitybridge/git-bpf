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

module GitHelpersMixin
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
