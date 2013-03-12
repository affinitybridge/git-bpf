#!/usr/bin/env ruby

# Ideally we would use a post-merge hook rather than having to check in our post-commit
# hook whether we've just done a merge commit. But post-merge hooks do not fire if there
# has been a merge conflict, even if it has been successfully dealt with by rerere. And
# the very thing we want to deal with post-merge is updating our rerere repo. So here we
# do a check to find out if the last commit was a merge commit. There may be a better way
# to check this but I don't know what it is.
parents = `git rev-list -n 1 --parents HEAD`.split("\s")

# Shift off the last commit.
last = parents.shift

if parents.length >= 2
  `git share-rerere pull`
  `git share-rerere push`
end
