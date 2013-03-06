#!/bin/bash

SCRIPT_DIR_NAME="ab-git-scripts"

SOURCE_URL="https://github.com/affinitybridge/git-scripts.git"
SOURCE_DIR="${HOME}/.${SCRIPT_DIR_NAME}"
SOURCE_CONTEXT="--work-tree=${SOURCE_DIR} --git-dir=${SOURCE_DIR}/.git"

TARGET_REPO="${1:-`pwd`}"
TARGET_DIR="${TARGET_REPO}/.git/${SCRIPT_DIR_NAME}"
TARGET_CONTEXT="--work-tree=${TARGET_REPO} --git-dir=${TARGET_REPO}/.git"

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
echo

read -p "Do you want to continue? [Y/n] " -n 1
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

echo Affinity Bridge git scripts have been installed.
echo
echo "To uninstall, run the following:"
echo -e "\trm ${TARGET_DIR}"
echo -e "\trm -rf ${SOURCE_DIR}"
echo -e "\tgit ${TARGET_CONTEXT} config --local --unset alias.recreate-branch"

