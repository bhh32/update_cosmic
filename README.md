# COSMIC Weekly Update Build Script - AerynOS
These are a collection of scripts that I use to build System76's COSMIC DE for AerynOS.

## Build from master branch
The `update_cosmic.sh` script builds the COSMIC DE packages from the master branch of each of the
upstream repositories.

## Build from a release tag
The `update_cosmic_tag.sh` script builds the COSMIC DE packages from a release tag. This build
script needs the builder to have their own fork of the [AerynOS recipes](https://github.com/AerynOS/recipes)
repository. The script will ask the builder to put the the URL of their fork into it so it can be
cloned and a new branch made within the fork. Please read the script and ensure that the tag you want
is the one within the script. If it is not, you will have to manually update the release tag.

## Auto-create Commits
The `make_commits.sh` script runs through each built package within the forked repository using
the `git status` command as a basis to know which ones need to be commited. It is VERY important
that if the builder does not want anything that isn't COSMIC DE related within their build branch
they should ensure the fork is clean of commits or uncommited changes BEFORE building from either
the `update_cosmic.sh` or `update_cosmic_tag.sh` scripts. The `make_commits.sh` script will not
determine what is or isn't COSMIC DE related!
