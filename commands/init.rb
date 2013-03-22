require 'lib/gitflow'
require 'lib/git-helpers'

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
    scripts = File.join(source.path, '.git', opts.script_dir_name)

    if not File.exists? scripts
      File.symlink source.path, scripts
    else if File.symlink? scripts
      Tty.ohai "Symbolic link to '#{source.path}' already exists."
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
    commands.each do |name|
      command = "ruby #{base_command} #{name}"
      target.cmd("config", "--local", "alias.#{name}", command)
    end


    #
    # 3. Set up rerere sharing.
    #
    target.config(true, "rerere.enabled", "true")
    target.config(true, "rerere.autoupdate", "true")

    rerere_path = File.join(target.git_dir, 'rr-cache')

    if not File.directory? rerere_path
      rerere = Repository::clone target.remote_url, rerere_path
    else if not File.directory? File.join(rerere_path, '.git')
      Tty.ohai "Rerere cache directory already exists; Initializing repository in existing rr-cache directory."
      rerere = Repository.init rerere_path
    else
      Tty.ohai "Rerere cache directory already exists and is a repository."
      rerere = Repository.new rerere_path
    end

    # TODO: Ensure orphan branch 'rr-cache' exists and that it is rerere's HEAD.

    #
    # 4. Symlink git-hooks.
    #

    #
    # Success!
    #
  end
end

