#!/bin/bash

# Check GAM version
echo "--Checking GAM version..."

###########################
###### SET VARIABLES ######
###########################

# Get the current user
currentUser=$(id -un) 

# Get the current version of GAMADV-XTD3
gam="/home/$currentUser/bin/gamadv-xtd3/gam"
currentVersion=$("$gam" version | head -n 1 | cut -d " " -f 2)

# Get the latest version of GAMADV-XTD3 from GitHub
latestVersion=$(curl -s https://api.github.com/repos/taers232c/GAMADV-XTD3/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')

###########################
#### COMPARE VERSIONS #####
###########################

if [ "$currentVersion" = "$latestVersion" ]; then
  echo "--GAM is running the latest version!"
else
  printf "\n--GAM is about to update! Please wait...\n\n"
  sleep 1  
  bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
fi