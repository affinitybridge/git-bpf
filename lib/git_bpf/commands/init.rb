require 'git-bpf/lib/gitflow'
require 'git-bpf/lib/git-helpers'
require 'git-bpf/lib/repository'

#
# init: 
#
class Init < GitFlow/'init'

  include GitHelpersMixin

  @documentation = ""

  def options(opts)
    opts.script_dir_name = 'git-bpf-scripts'
    opts.remote_name = 'origin'
    opts.rerere_branch = 'rr-cache'

    [
      ['-d', '--directory-name NAME',
        "",
        lambda { |n| opts.script_dir_name = n }],
      ['-r', '--remote-name NAME',
        "",
        lambda { |n| opts.remote_name = n }],
      ['-b', '--rerere-branch NAME',
        "",
        lambda { |n| opts.rerere_branch = n }],
    ]
  end

  def execute(opts, argv)
    if argv.length > 1
      run 'init', '--help'
      terminate
    end

    source = Repository.new File.join(File.dirname(__FILE__), '../')
    target = Repository.new(argv.length == 1 ? argv.pop : Dir.getwd)


    #
    # 1. Link source scripts directory.
    #
    ohai "1. Linking scripts directory to '#{source.path}'."

    scripts = File.join(target.path, '.git', opts.script_dir_name)

    if not File.exists? scripts
      File.symlink source.path, scripts
    elsif File.symlink? scripts
      opoo "Symbolic link already exists."
    else
      terminate "Cannot create symbolic link (#{scripts})."
    end


    #
    # 2. Create aliases for commands.
    #
    base_command = File.join('.git', opts.script_dir_name, 'bpf.rb')
    commands = [
      'recreate-branch',
      'share-rerere',
    ]

    ohai "2. Creating aliases for commands:", commands.shell_list

    commands.each do |name|
      command = "!ruby #{base_command} #{name}"
      target.cmd("config", "--local", "alias.#{name}", command)
    end


    #
    # 3. Set up rerere sharing.
    #
    ohai "3. Setting up rerere sharing."

    target.config(true, "rerere.enabled", "true")
    target.config(true, "rerere.autoupdate", "true")

    rerere_path = File.join(target.git_dir, 'rr-cache')
    target_remote_url = target.remoteUrl(opts.remote_name)

    if not File.directory? rerere_path
      rerere = Repository::clone target_remote_url, rerere_path
    elsif not File.directory? File.join(rerere_path, '.git')
      opoo "Rerere cache directory already exists; Initializing repository in existing rr-cache directory."
      rerere = Repository.init rerere_path
      rerere.cmd("remote", "add", opts.remote_name, target_remote_url)
    else
      opoo "Rerere cache directory already exists and is a repository."
      rerere = Repository.new rerere_path
    end

    rerere.fetch opts.remote_name

    if rerere.branch?('rr-cache', opts.remote_name)
      # Remote has branch 'rr-cache', make sure we are currently on it.
      if not rerere.head.include? "rr-cache"
        rerere.cmd("checkout", "rr-cache")
      end
    else
      # Create orphan branch 'rr-cache' and push to remote.
      rerere.cmd("checkout", "--orphan", "rr-cache")
      rerere.cmd("rm", "-rf", "--ignore-unmatch", "#{rerere_path}/")
      rerere.cmd("commit", "-a", "--allow-empty", "-m", "Automatically creating branch to track conflict resolutions.")
      rerere.cmd("push", opts.remote_name, "rr-cache")
    end


    #
    # 4. Symlink git-hooks.
    #
    hooks_dir = File.join(target.git_dir, "hooks")
    hooks = [
      'post-merge',
      'post-checkout'
    ]

    ohai "4. Creating symbolic links to git-hooks:", hooks.shell_list

    hooks.each do |name|
      target_hook_path = File.join(hooks_dir, name)
      source_hook_path = File.join(scripts, "hooks", "#{name}.rb")
      files = Dir.glob("#{target_hook_path}*")
      write = files.empty?

      if not write and promptYN "Existing hook '#{name}' detected, overwrite?"
        write = File.delete(files.shell_s) > 0
      end

      if write
        File.symlink source_hook_path, target_hook_path
      else
        opoo "Couldn't link '#{name}' hook as it already exists."
      end
    end

    #
    # Success!
    #
    ohai "Success!"
  end
end
