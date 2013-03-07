require 'lib/gitflow'
require 'lib/git-helpers'

#
# recreate_branch: Recreate a branch based on the merge commits it's comprised of.
#
class RecreateBranch < GitFlow/'recreate-branch'

  include GitHelpersMixin

  @@prefix = "BRANCH-PER-FEATURE-PREFIX"

  @documentation = "Recreates the source branch in place or as a new branch by re-merging all of the merge commits."


  def options(opts)
    opts.base = 'master'
    opts.exclude = []

    [
      ['-a', '--base NAME',
        "A reference to the commit from which the source branch is based, defaults to #{opts.base}.",
        lambda { |n| opts.base = n }],
      ['-b', '--branch NAME',
        "Instead of deleting the source branch and replacng it with a new branch of the same name, leave the source branch and create a new branch called NAME.",
        lambda { |n| opts.branch = n }],
      ['-x', '--exclude NAME',
        "Specify a list of branches to be excluded.",
        lambda { |n| opts.exclude.push(n) }],
    ]
  end

  def execute(opts, argv)
    if argv.length != 1
      run('recreate-branch', '--help')
      terminate
    end

    source = argv.pop

    # If no new branch name provided, replace the source branch.
    opts.branch = source if opts.branch == nil

    # Perform some validation.
    if not branchExists? source
      terminate "Cannot recreate branch #{source} as it doesn't exist."
    end

    if opts.branch != source and branchExists? opts.branch
      terminate "Cannot create branch #{opts.branch} as it already exists."
    end

    if not refExists? opts.base
      terminate "Cannot find reference '#{opts.base}' to use as a base for new branch: #{opts.branch}."
    end

    #
    # 1. Compile a list of merged branches from source branch.
    #
    puts "1. Processing branch '#{source}' for merge-commits..."

    # Remove from the list any branches that have been explicity excluded using
    # the -x option
    branches = getMergedBranches(opts.base, source).reject do |item| 
      stripped = item.gsub /^remotes\/\w+\/([\w\-\/]+)$/, '\1'
      opts.exclude.include? stripped
    end

    # Prompt to continue.
    puts "The following branches will be merged when the new #{opts.branch} branch is created:\n - #{branches.join("\n - ")}"
    puts "If you see something unexpected check that your '#{source}' branch is up to date and also '#{opts.base}' if it is branch."
    if not promptYN "Proceed with #{source} branch recreation?"
      terminate "Aborting."
    end

    #
    # 2. Backup existing local source branch.
    #
    tmp_source = "#{@@prefix}-#{source}"
    puts "2. Creating backup of #{source}, #{tmp_source}..."

    if branchExists? tmp_source
      terminate "Cannot create branch #{tmp_source} as one already exists. To continue, #{tmp_source} must be removed."
    end

    git('branch', '-m', source, tmp_source)

    #
    # 3. Create new branch based on 'base'.
    #
    puts "3. Creating new '#{opts.branch}' branch based on '#{opts.base}'..."

    git('checkout', '-b', opts.branch, opts.base, '--quiet')

    #
    # 4. Begin merging in feature branches.
    #
    puts "4. Merging in feature branches..."

    branches.each do |branch|
      begin
        puts " - Attempting to merge '#{branch}'."
        # Attempt to merge in the branch. If there is no conflict at all, we
        # just move on to the next one.
        git('merge', '--quiet', '--no-ff', '--no-edit', branch)
      rescue
        # There was a conflict. If there's no available rerere for it then it is
        # unresolved and we need to abort as there's nothing that can be done
        # automatically.
        conflicts = git('rerere', 'status').chomp.split("\n")

        if conflicts.length != 0
          puts "\n"
          puts "There is a merge conflict with branch #{branch} that has no rerere."
          puts "Record a resoloution by resolving the conflict."
          puts "Then run the following command to return your repository to its original state."
          puts "\n"
          puts "git reset --hard #{tmp_source} && git branch -D #{tmp_source}"
          puts "\n"
          puts "If you do not want to resolve the conflict, it is safe to just run the above command to restore your repository to the state it was in before executing this command."
          terminate
        else
          # Otherwise, we have a rerere and the changes have been staged, so we
          # just need to commit.
          git('commit', '-a', '--no-edit')
        end
      end
    end

    #
    # 5. Clean up.
    #
    puts "5. Cleaning up temporary branches (#{tmp_source})."

    if source != opts.branch
      git('branch', '-m', tmp_source, source)
    else
      git('branch', '-D', tmp_source)
    end
  end

  def getMergedBranches(base, source)
    branches = []
    merges = git('rev-list', '--parents', '--merges', '--reverse', "#{base}...#{source}").strip

    merges.split("\n").each do |commits|
      parents = commits.split("\s")
      commit = parents.shift

      parents.each do |parent|
        name = git('name-rev', parent, '--name-only').strip
        unless name.include? base or name.include? source
          branches.push name
        end
      end
    end

    return branches
  end
end
