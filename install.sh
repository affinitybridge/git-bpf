#!/bin/bash

#
# Usage: ./install.sh <path_to_repository>
#
# Where <path_to_repository> is the path to the repository you wish to install
# these scripts to. If nothing is provided, it will default to the current
# directory.
#

SCRIPT_DIR_NAME="ab-git-scripts"
TARGET_REMOTE_NAME="origin"
TARGET_RERERE_BRANCH="rr-cache"

SOURCE_URL="https://github.com/affinitybridge/git-scripts.git"
SOURCE_DIR="${HOME}/.${SCRIPT_DIR_NAME}"
SOURCE_CONTEXT="--work-tree=${SOURCE_DIR} --git-dir=${SOURCE_DIR}/.git"

TARGET_REPO="${1:-`pwd`}"
TARGET_CONTEXT="--work-tree=${TARGET_REPO} --git-dir=${TARGET_REPO}/.git"
TARGET_DIR="${TARGET_REPO}/.git/${SCRIPT_DIR_NAME}"
TARGET_RERERE_REPO="${TARGET_REPO}/.git/rr-cache"
TARGET_RERERE_CONTEXT="--work-tree=${TARGET_RERERE_REPO} --git-dir=${TARGET_RERERE_REPO}/.git"

TARGET_REMOTE_URL=`git ${TARGET_CONTEXT} config --get remote.${TARGET_REMOTE_NAME}.url`
# TARGET_REMOTE_URL=${TARGET_REPO}/`git ${TARGET_CONTEXT} config --get remote.${TARGET_REMOTE_NAME}.url`

COMMAND_RECREATE_BRANCH="ruby .git/${SCRIPT_DIR_NAME}/bpf.rb recreate-branch"
COMMAND_SHARE_RERERE="ruby .git/${SCRIPT_DIR_NAME}/bpf.rb share-rerere"

link_hooks() {
  if [ ! -L ${TARGET_REPO}/.git/hooks/${1} ]; then
    # Link scripts into repository.
    ln -s ../${SCRIPT_DIR_NAME}/hooks/${1}.rb ${TARGET_REPO}/.git/hooks/${1}
  fi
}

echo
echo "* INSTALLING AFFINITY BRIDGE GIT SCRIPTS *"

# Validate target repository before continuing.
if [ ! -d "${TARGET_REPO}/.git" ]; then
  echo -e "Error - Provided directory doesn't exist or isn't a git repository:"
  echo -e "\t${TARGET_REPO}"
  echo "Either provide a path to a valid git repository or execute this script"
  echo "from within a repository."
  exit 1
fi

echo -e "
If this is the first time running this script a copy of the AB git scripts
repo will be cloned into your home directory.

If you already have a copy of the scripts in your home directory, we'll
make sure it is up to date.

The directory will then be sym-linked into the target repository and local
git aliases will be created for each command.

Details:
 - AB scripts source URL:\n\t${SOURCE_URL}
 - Scripts will be located:\n\t${SOURCE_DIR}
 - The repository where the scripts the will be installed:\n\t${TARGET_REPO}
 - git-rerere will be enabled in '${TARGET_REPO}'
 - git-rerere will be configured to automatically stage successful resolutions
 - A .git/rr-cache directory will be set up to synchronize with '${TARGET_REMOTE_NAME}/${TARGET_RERERE_BRANCH}'.

NOTE: You may be asked to authenticate with a username & password.
      This prompt is from GitHub. You can find instructions on how to
      automatically authenticate here: https://help.github.com/articles/set-up-git#password-caching.
"

read -p "Do you want to continue? [y/N] " -n 1
echo

# If reply is anything other than [Yy], exit.
if [[ ! ${REPLY} =~ ^[Yy]$ ]]
then
  exit 1
fi

# Check to see if the git scripts already exist.
if [ ! -d ${SOURCE_DIR} ]; then
  # Install local copy of scripts to home dir.
  git clone --quiet ${SOURCE_URL} ${SOURCE_DIR}
else
  # Make sure local copy of scripts is up to date.
  git ${SOURCE_CONTEXT} pull --quiet origin master
fi

# If there is already a link in the target repository's .git dir, remove it.
if [ -L ${TARGET_DIR} ]; then
  rm ${TARGET_DIR}
fi

# Link scripts into repository.
ln -s ${SOURCE_DIR} ${TARGET_DIR}

# Create local git aliases for scripts.
git ${TARGET_CONTEXT} config --local alias.recreate-branch "!${COMMAND_RECREATE_BRANCH}"
git ${TARGET_CONTEXT} config --local alias.share-rerere "!${COMMAND_SHARE_RERERE}"

# Set up rerere sharing.
git ${TARGET_CONTEXT} config --local rerere.enabled true
git ${TARGET_CONTEXT} config --local rerere.autoupdate true

if [ ! -d ${TARGET_REPO}/.git/rr-cache ]; then
  mkdir ${TARGET_REPO}/.git/rr-cache
fi

if [ ! -d ${TARGET_REPO}/.git/rr-cache/.git ]; then
  git ${TARGET_RERERE_CONTEXT} init --quiet
  git ${TARGET_RERERE_CONTEXT} remote add ${TARGET_REMOTE_NAME} ${TARGET_REMOTE_URL}
  git ${TARGET_RERERE_CONTEXT} fetch --all --quiet

  # TODO: Check if ${TARGET_REMOTE_NAME}/${TARGET_RERERE_BRANCH} exists before checking it out.
  git ${TARGET_RERERE_CONTEXT} checkout -b ${TARGET_RERERE_BRANCH} ${TARGET_REMOTE_NAME}/${TARGET_RERERE_BRANCH} --quiet
fi

# Set up hooks.
link_hooks "post-commit"

echo -e "
Affinity Bridge git scripts have been installed.

To uninstall, run the following:
  rm ${TARGET_DIR}
  rm -rf ${SOURCE_DIR}
  git ${TARGET_CONTEXT} config --local --unset alias.recreate-branch
  git ${TARGET_CONTEXT} config --local --unset alias.share-rerere
  git ${TARGET_CONTEXT} config --local --unset rerere.enabled
  git ${TARGET_CONTEXT} config --local --unset rerere.autoupdate
  rm -rf ${TARGET_RERERE_REPO}/.git
"
