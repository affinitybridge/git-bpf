Affinity Bridge's BPF Scripts
=============================

## Cammands

### git-recreate-branch

Usage: ```git recreate-branch <source-branch> [OPTIONS]...```

Recreates <source-branch> in-place or as a new branch by re-merging all of the merge commits which it is comprised of.

    OPTIONS
        -a, --base NAME                  A reference to the commit from which the source branch is based, defaults to master.
        -b, --branch NAME                Instead of deleting the source branch and replacng it with a new branch of the same name, leave the source branch and create a new branch called NAME.
        -x, --exclude NAME               Specify a list of branches to be excluded.
        -l, --list                       Process source branch for merge commits and list them. Will not make any changes to any branches.


### git-share-rerere

A collection of commands to help share your rr-cache.

    OPTIONS
        -c, --cache_dir DIR              The location of your rr-cache dir, defaults to .git/rr-cache.
        -g, --git-dir DIR                The location of your rr-cache .git dir, defaults to .git/rr-cache/.git.
        -b, --branch NAME                The name of the branch your rr-cache is stored in, defaults to rr-cache.
        -r, --remote NAME                The name of the remote to use when getting the latest rr-cache, defaults to origin.

**Sub-commands - Usage:**

```git share-rerere push```

Push any new resolutions to the designated <branch> on the remote.

```git share-rerere pull```

Pull any new resolutions to the designated <branch> on the remote.

## Install
