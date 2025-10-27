#!/usr/bin/env bash

UPDATE_REPO=${HOME}/Documents/contribs/cosmic_weekly/aerynos-recipes
LOG_DIR=${HOME}/Documents/contribs/cosmic_weekly/logs
COSMIC_SRC=/tmp/cosmic_src

if [ ! -d "$LOG_DIR" ]; then
  mkdir -p $LOG_DIR
fi

# Give temporary user access to /tmp
sudo chown $USER:root /tmp

mkdir -p $COSMIC_SRC

base_dir="${UPDATE_REPO}/c"
x_base_dir="${UPDATE_REPO}/x/xdg-desktop-portal-cosmic"
wksp_epoch="${COSMIC_SRC}/cosmic-workspaces-epoch"
xdg_src="${COSMIC_SRC}/xdg-desktop-portal-cosmic"
cwd=$(pwd)


cd $base_dir

# Create LOG_DIR for this build
if [ ! -d "${LOG_DIR}/$(date -I date)" ]; then
  mkdir -p ${LOG_DIR}/$(date -I date)
fi

# Reset the LOG_DIR variable to the created date directory
LOG_DIR=${LOG_DIR}/$(date -I date)

# Create a failure list
failure_lst="$(date -I date)-package-failures.lst"
touch ${LOG_DIR}/$failure_lst

# Create a success list
success_lst="$(date -I date)-package-successes.lst"
touch ${LOG_DIR}/$success_lst

# Ensure the branch is unique to the week it's being updated
# Uncomment this for the first run of the week, comment it back out after the first run.
#git checkout 2025-05-repo-rebuild
#git pull -r https://github.com/aerynos/recipes.git 2025-05-repo-rebuild
#git push -f
git checkout -b $(date -I date)-cosmic-update

for pkg in *; do
    if [[ "$pkg" == "cosmic-"* ]]; then
      if [[ "$pkg" == "cosmic-workspace" ]]; then
        pkg="${pkg}-epoch"
      else      
        if [[ "$pkg" == "cosmic-desktop" ]]; then
          cd $base_dir
          continue
        fi

        

        cd "${COSMIC_SRC}"

        git clone https://github.com/pop-os/${pkg}.git
        cd $pkg

        if [[ "$pkg" == "cosmic-workspace-epoch" ]]; then
          pkg=$(echo $pkg | sed 's/-epoch//g')
        fi
      fi

      echo "Current dir: $(pwd)"

      # Get the most up-to-date commit hash from the repo   
      update_hash=$(git rev-parse HEAD)

      # Switch to the update repo
      cd "${base_dir}/${pkg}"

      echo "In package dir: $pkg"

      # Get the currently deployed commit hash
      cur_hash=$(cat stone.yaml | grep .git | grep -v homepage | grep -v version | awk '{ print $4 }')

      if [[ "${update_hash}" != "${cur_hash}" ]]; then
        echo "Updating: $pkg"
        version=$(cat stone.yaml | grep version | awk '{ print $3 }')
        echo "Current version: ${version}"
        boulder recipe update --ver 1.0.0-beta.3+git."${update_hash:0:7}" --upstream "git|${update_hash}" stone.yaml -w
        version=$(cat stone.yaml | grep version | awk '{ print $3 }')
        echo "Updated version: ${version}"
        if [[ "$?" == "0" ]]; then
          boulder build --profile local-x86_64

          if [[ "$?" == "0" ]]; then
            just mv-local
            notify-send "Successful Build" "$pkg successfully built please review"
          else
            notify-send "Failed Build" "$pkg failed to build; please review"
            cd $base_dir
            # Send the failure to the failure list
            echo "$pkg failed to build" >> ../$failure_lst
            continue
          fi
        else
          # Send the notification that the package failed to update
          notify-send "Failed Update" "$pkg failed to update!"
          # Checkout the directory to remove anything that did get updated
          git checkout .
          cd $base_dir
          # Send the failure to the failure list
          echo "$pkg failed to update" >> ../$failure_lst
          continue
        fi
        # Send to the success list
        cd $base_dir
        echo $pkg >> ../$success_lst
      fi          
    else
      cd $base_dir
      continue
    fi
done

# Clone the xdg-desktop-portal-cosmic repo
cd $COSMIC_SRC
git clone https://github.com/pop-os/xdg-desktop-portal-cosmic.git

# Switch to the repo and cache the latest hash
cd $xdg_src
update_hash=$(git rev-parse HEAD)

# Switch to the update repo directory and get the current hash
cd $x_base_dir
cur_hash=$(cat stone.yaml | grep .git | grep -v homepage | grep -v version | awk '{print $4 }')

if [[ "${update_hash}" != "${cur_hash}" ]]; then
  echo "Updating: xdg-desktop-portal-cosmic"
  version=$(cat stone.yaml | grep version | awk '{ print $3 }')
  echo "Current version: ${version}"
  boulder recipe update --ver 1.0.0-beta.3+git."${update_hash:0:7}" --upstream "git|${update_hash}" stone.yaml -w
  version=$(cat stone.yaml | grep version | awk '{ print $3 }')
  echo "Updated version: ${version}"

  if [[ "$?" == "0" ]]; then
    boulder build --profile local-x86_64

    if [[ "$?" == "0" ]]; then
      just mv-local
      notify-send "Successful Build" "xdg-desktop-portal-cosmic successfully built; please review"
      # Send to the success list
      cd $base_dir
      echo $pkg >> ../$success_lst
    else
      notify-send "Failed Build" "xdg-desktop-portal-cosmic failed to build; please review"
      # Add to the failure list
      cd $base_dir
      echo "$pkg failed to build" >> ../$failure_lst
    fi
  else
    notify-send "Failed Update" "xdg-desktop-portal-cosmic failed to update!"
    git checkout .
    # Add to the failure list
    echo "$pkg failed to update" >> ../$failure_lst
  fi
fi

# Return /tmp ownership to root
sudo chown root:root /tmp

# Return to the directory that the script was ran from
cd $cwd
