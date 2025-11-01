#!/bin/env bash

# Get maintainers repo
read -p "Enter your AerynOS recipe fork's URL: " fork

UPDATE_BASE=${HOME}/Documents/contribs/cosmic_weekly
UPDATE_REPO="${UPDATE_BASE}/$(echo $fork | awk -F'/' '{ print $NF }')"
LOG_DIR=${HOME}/Documents/contribs/cosmic_weekly/logs
COSMIC_SRC=/tmp/cosmic_src/
cwd=$(pwd)

# Create the update repo if it doesn't exist
if [ ! -d "$UPDATE_REPO" ]; then
  mkdir -pv $UPDATE_BASE
  cd $UPDATE_BASE
  git clone $fork
fi

# Create the log directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
  mkdir -pv $LOG_DIR/$(date -I date)
fi

# If the base LOG_DIR exists, check to see if the log directory for today exists
if [ ! -d "${LOG_DIR}/$(date -I date)" ]; then
  mkdir -pv $LOG_DIR/$(date -I date)
fi

LOG_DIR=$LOG_DIR/$(date -I date)

# Create the log files
failure_log="${LOG_DIR}/$(date -I date)-package-failures.log"
success_log="${LOG_DIR}/$(date -I date)-package-successes.log"

touch $failure_log $success_log

# Setup /tmp for cosmic source code
sudo chown $USER:root /tmp
mkdir -pv $COSMIC_SRC

cd "$UPDATE_REPO/c"

# Create a unique branch in the update repo
git checkout 2025-05-repo-rebuild
git pull -r https://github.com/aerynos/recipes.git 2025-05-repo-rebuild
git push
git checkout -b $(date -I date)-cosmic-update

for pkg in *; do
  if [[ "$pkg" == "cpio" ]]; then
    cd $UPDATE_REPO/x
    pkg="xdg-desktop-portal-cosmic"
  fi
  
  if [[ "$pkg" == *"cosmic"* ]]; then

    if [[ "$pkg" == "cosmic-workspaces" ]]; then
      pkg="${pkg}-epoch"
    else
      if [[ "$pkg" == "cosmic-desktop" ]]; then
        cd "$UPDATE_REPO/c"
        continue
      fi

      cd "${COSMIC_SRC}"

      git clone https://github.com/pop-os/${pkg}.git
      cd $pkg

      if [[ "$pkg" == "cosmic-workspaces-epoch" ]]; then
        pkg=$(echo $pkg | sed 's/-epoch//g')
      fi
    fi

    # Get the beta tag commit
    git checkout epoch-1.0.0-beta.4
    beta_hash=$(git rev-parse HEAD)

    # Switch to the update repo
    if [[ "$pkg" != "xdg-desktop-portal-cosmic" ]]; then
      cd "${UPDATE_REPO}/c/$pkg"
    else
      cd "${UPDATE_REPO}/x/$pkg"
    fi

    version="1.0.0-beta.4.git+${beta_hash:0:7}"
    boulder recipe update --ver $version --upstream "git|${beta_hash}" stone.yaml -w  

    if [[ "$?" == "0" ]]; then
      boulder build --profile local-x86_64

      if [[ "$?" == "0" ]]; then
        just mv-local
        notify-send "Successful Build" "$pkg successfully built; please review"
      else
        notify-send "Failed Build" "$pkg failed to build; please review"
        echo "$pkg: $version" >> $failure_log
        continue
      fi
    else
      notify-send "Failed Package Update" "$pkg failed to update!"
      git checkout .
      echo "$pkg: $version" >> $failure_log
    fi
  fi
done
