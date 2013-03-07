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
    puts "\n-> #{message} [y/n]"
    unless STDIN.gets.chomp == 'y'
      return false
    end
    puts "\n"
    return true
  end
end
