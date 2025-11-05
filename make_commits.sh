#!/bin/env bash

### IMPORTANT!
# Make sure that you are in the root of your packaging repo before you run this script!
repo_root=$(pwd)

for pkg in $(git status | grep modified | awk '{ print $2 }'); do
  # Change to the top directory in the git status list
  pkg_dir=$(echo $pkg | awk -F'/' '{ print $1"/"$2 }')
  echo "Changing directory to: {$pkg_dir}"
  cd $pkg_dir
  git add .
  pkg_name=$(echo $pkg | awk -F'/' '{ print $2 }')
  vers=$(cat stone.yaml | grep version | awk '{ print $3 }')
  git commit -m "${pkg_name}: Update to ${vers}"
  cd $repo_root
done
