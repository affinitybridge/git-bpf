require 'lib/gitflow'
require 'lib/git-helpers'

module ShareReReReMixin
  def options(opts)
    opts.work_tree = ".git/rr-cache"
    opts.git_dir = "#{opts.work_tree}/.git"
    opts.branch = "rr-cache"
    opts.remote = "origin"

    [
      ['-c', '--cache_dir DIR',
        "The location of your rr-cache dir, defaults to #{opts.work_tree}.",
        lambda { |n| opts.rr_cache_dir = n }],
      ['-g', '--git-dir DIR',
        "The location of your rr-cache .git dir, defaults to #{opts.git_dir}.",
        lambda { |n| opts.git_dir = n }],
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

  @documentation = <<-HELP.undent
    A collection of commands to help share your rr-cache.

    Available commands:
     - push
     - pull
  HELP

  def execute(opts, argv)
    run('share-rerere', '--help')
  end

  class PullReReRe < ShareReReRe/'pull'

    @help = "Pull the latest conflict resolutions."

    include GitHelpersMixin
    include ShareReReReMixin

    def execute(opts, argv)
      ctx = { git_dir: opts.git_dir, work_tree: opts.work_tree }
      git(*context(ctx, "pull", '--quiet', opts.remote, opts.branch))
    end
  end

  class PushReReRe < ShareReReRe/'push'

    @help = "Push your latest conflict resolutions."

    include GitHelpersMixin
    include ShareReReReMixin

    def execute(opts, argv)
      ctx = { git_dir: opts.git_dir, work_tree: opts.work_tree }
      lines = git(*context(ctx, "status", "--porcelain")).split("\n").map { |a| a.chomp }
      if lines.empty?
        terminate "No resolutions to share."
      end

      lines.each do |line|
        if line =~ /^\?\?\s(\w+)\//
          folder = line.split("\s").last
          message = "Sharing resolution: #{folder}."
          git(*context(ctx, "add", folder))
          git(*context(ctx, "commit", "-m", message))
          git(*context(ctx, "push", "--quiet", opts.remote, opts.branch))
          puts message
        end
      end
    end
  end

end
