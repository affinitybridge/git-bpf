#!/bin/bash

SCRIPT_DIR_NAME="ab-git-scripts"

SOURCE_URL="https://github.com/affinitybridge/git-scripts.git"
SOURCE_DIR="${HOME}/.${SCRIPT_DIR_NAME}"
SOURCE_CONTEXT="--work-tree=${SOURCE_DIR} --git-dir=${SOURCE_DIR}/.git"

TARGET_REPO="${1:-`pwd`}"
TARGET_DIR="${TARGET_REPO}/.git/${SCRIPT_DIR_NAME}"
TARGET_CONTEXT="--work-tree=${TARGET_REPO} --git-dir=${TARGET_REPO}/.git"

COMMAND_RECREATE_BRANCH="ruby .git/${SCRIPT_DIR_NAME}/bpf.rb recreate-branch"

echo "If this is the first time running this script a copy of the AB git scripts repo (${SOURCE_URL}) will be cloned into your home directory (${SOURCE_DIR})."
echo "If you already have a copy of the scripts in your home directory, we'll make sure it's up to date."
echo "The directory will then be sym-linked into the target repository (${TARGET_REPO}) and local git aliases will be created for each command."
read -p "Do you want to continue? " -n 1
if [[ ! ${REPLY} =~ ^[Yy]$ ]]
then
  exit 1
fi

if [ ! -d ${SOURCE_DIR} ]; then
  # Install local copy of scripts to home dir.
  git clone --quiet ${SOURCE_URL} ${SOURCE_DIR}
else
  # Make sure local copy of scripts is up to date.
  git ${SOURCE_CONTEXT} pull --quiet origin master
fi

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
echo "*** WARNING: be smart, don't blindly copy + paste! ***"
echo " - rm ${TARGET_DIR}"
echo " - rm -rf ${SOURCE_DIR}"
echo " - git ${TARGET_CONTEXT} config --local --unset alias.recreate-branch"

