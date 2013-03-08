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

# TARGET_REMOTE_URL=`git ${TARGET_CONTEXT} config --get remote.${TARGET_REMOTE_NAME}.url`
TARGET_REMOTE_URL=${TARGET_REPO}/`git ${TARGET_CONTEXT} config --get remote.${TARGET_REMOTE_NAME}.url`

COMMAND_RECREATE_BRANCH="ruby .git/${SCRIPT_DIR_NAME}/bpf.rb recreate-branch"

echo
echo "* INSTALLING AFFINITY BRIDGE GIT SCRIPTS *"
echo

# Validate target repository before continuing.
if [ ! -d "${TARGET_REPO}/.git" ]; then
  echo "Error - Provided directory doesn't exist or isn't a git repository:"
  echo -e "\t${TARGET_REPO}"
  echo "Either provide a path to a valid git repository or execute this script"
  echo "from within a repository."
  exit 1
fi

echo "If this is the first time running this script a copy of the AB git scripts"
echo "repo will be cloned into your home directory."
echo
echo "If you already have a copy of the scripts in your home directory, we'll"
echo "make sure it is up to date."
echo
echo "The directory will then be sym-linked into the target repository and local"
echo "git aliases will be created for each command."
echo
echo "Details:"
echo -e " - AB scripts source URL:\n\t${SOURCE_URL}"
echo -e " - Scripts will be located:\n\t${SOURCE_DIR}"
echo -e " - The repository where the scripts the will be installed:\n\t${TARGET_REPO}"
echo -e " - git-rerere will be enabled in '${TARGET_REPO}'"
echo -e " - git-rerere will be configured to automatically stage successful resolutions"
echo -e " - A .git/rr-cache directory will be set up to synchronize with '${TARGET_REMOTE_NAME}/${TARGET_RERERE_BRANCH}'."
echo

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
  git ${TARGET_RERERE_CONTEXT} checkout -b ${TARGET_RERERE_BRANCH} ${TARGET_REMOTE_NAME}/${TARGET_RERERE_BRANCH} --quiet
fi

echo "Affinity Bridge git scripts have been installed."
echo
echo "To uninstall, run the following:"
echo -e "\trm ${TARGET_DIR}"
echo -e "\trm -rf ${SOURCE_DIR}"
echo -e "\tgit ${TARGET_CONTEXT} config --local --unset alias.recreate-branch"
echo -e "\tgit ${TARGET_CONTEXT} config --local --unset rerere.enabled"
echo -e "\tgit ${TARGET_CONTEXT} config --local --unset rerere.autoupdate"
echo -e "\trm -rf ${TARGET_RERERE_REPO}/.git"
