#!/bin/bash

###########################
###### CHECK FOR DIRS #####
###########################

# Creating an 'Offboarded' folder if it doesn't exist
if [ -d "$HOME/Offboarded" ] 
then
    printf "Offboarded folder exists. Proceeding...\n\n" 
else
    printf "Offboarded folder doesn't exist. Creating...\n\n"
    mkdir "$HOME"/Offboarded
fi

# Checking for GAM
if [ ! -d "$HOME/bin/gam" ] && [ ! -d "$HOME/bin/gamadv-xtd3" ]
then
    printf "GAM is not installed. Please install it by following our Wiki: <Insert Internal Documentation Link Here> \n\n"
    exit 0
elif [ -d "$HOME/bin/gam" ]
then
    printf "Only GAM is installed. Please install 'GAM ADV' via: https://github.com/taers232c/GAMADV-XTD3/wiki/How-to-Upgrade-from-Standard-GAM or reset your Cloud Shell then follow our Wiki: <Insert Internal Documentation Link Here> \n\n"
    exit 0
elif [ -d "$HOME/bin/gamadv-xtd3" ]
then
    printf "GAM ADV exists. Proceeding...\n\n"
fi

###########################
##### CHECK THE USER ######
###########################

# Define expression pattern for email validation
emailPattern='^[a-zA-Z0-9._%+-]+@company\.com$'

# Prompt for user email
while true; do
    read -r -p "Enter offboarding user email: " userEmail

    # Validate email format
    if [[ $userEmail =~ $emailPattern ]]; then
        break
    else
        printf "Error: Invalid email format or incorrect domain.\n\n"
    fi
done

# Get user type
userType=""

# Prompt for user type
while [[ "$userType" != "employee" && "$userType" != "Employee" && "$userType" != "contractor" && "$userType" != "Contractor" ]]; do

    read -r -p "Enter user-type (contractor or employee): " userType

    # Check if user type is valid
    if [[ "$userType" != "employee" && "$userType" != "Employee" && "$userType" != "contractor" && "$userType" != "Contractor" ]]; then
        printf "Error: Invalid user-type. Type 'Employee' or 'Contractor'.\n\n"
  fi
done

# User is valid, proceed with script
printf "\nEmail: %s is a valid format. Type: %s is a valid type.\n\n" "$userEmail" "$userType"

# Confirm user's choice
read -r -p "Are you sure you want to proceed with offboarding user '$userEmail'? (y/n) " confirm
if [[ "$confirm" != "y" ]]; then
    printf "Offboarding cancelled.\n\n"
    exit 1
else
    printf "Offboarding %s...\n\n" "$userEmail"
fi

# Lag time
sleep 1

###########################
#### SETTING VARIABLES ####
###########################

# Today's date
today=$(date +%Y-%m-%d)
# Gam binary path
gam="$HOME/bin/gamadv-xtd3/gam"
# Offboarded user folder path
userPath=$HOME/Offboarded/$userEmail
# Log file
logFile="$userPath"/logFile-"$today".txt
# Managed mobile device list
mdmList="$userPath"/mdmList-"$today".csv
# Shared drive list
shrdDrvList="$userPath"/"$userEmail"-shrdDrv.csv
# Managers email
managerEmail=$($gam info user $userEmail | awk '/type: manager/ {getline; print $2}')
# IT Calendar
itCal="<sharedGoogleCalendarId>"
# 90 Days from today
ninetyDays=$(date -d "+90 days" +%Y-%m-%d)

###########################
##### SET UP FUNCTION #####
###########################

# Create folder for offboarding user if it doesn't exist
if [ -d "$userPath" ] 
then
    printf "User offboarding folder exists. Proceeding...\n\n" 
else
    printf "User offboarding folder doesn't exist. Creating...\n\n"
    mkdir "$userPath"
fi
printf "\n\n--/--\n\n"

# Function code
offboard() {
printf "\n\n--START--\n\n"

# Reset user's sign-in cookies & set a random pass
echo "Resetting sign-in cookies and setting a random password"
$gam user "$userEmail" signout
$gam update user "$userEmail" password random
sleep 0.5
printf "\n\n--/--\n\n"

# Turn off directory sharing for user
echo "Turning 'Directory Sharing' off"
$gam update user "$userEmail" gal off
sleep 0.5
printf "\n\n--/--\n\n"

# Create list of all shared drives
echo "Creating list of all shared drives"
$gam user "$userEmail" print shareddrives fields id,name > "$shrdDrvList"

# Delete all shared drives from user
echo "Removing shared drive access"
$gam csv "$shrdDrvList" gam delete drivefileacl ~id ~User

# Remove user from all groups
echo "Removing user from Google Groups"
$gam user "$userEmail" delete groups
sleep 0.5
printf "\n\n--/--\n\n"

# Remove connected applications, backup codes and/or tokens
echo "Removing connected apps, backup codes and/or tokens"
$gam user "$userEmail" deprovision
sleep 0.5
printf "\n\n--/--\n\n"

# Create file with resourceIds of the 'mdmList'
echo "Creating list of managed mobile device resourceIds"
$gam config csv_output_header_filter "resourceId" redirect csv - > "$mdmList" print mobile query "email:$userEmail"
sleep 1
printf "\n\n--/--\n\n"

# Wipe account from managed devices
echo "Removing Google account from managed mobile device(s)"
$gam csv "$mdmList" gam update mobile ~resourceId action account_wipe
sleep 1
printf "\n\n--/--\n\n"

# Remove devices from Google Workspace device management
echo "Removing managed mobile device(s) from Google MDM"
$gam csv "$mdmList" gam delete mobile ~resourceId
sleep 0.5
printf "\n\n--/--\n\n"

# # Transfer the users calendar to their manager
# echo "Transferring Google Calendar to manager on file"
# $gam create transfer $userEmail calendar $managerEmail releaseresources
# sleep 1
# printf "\n\n--/--\n\n"

# # Transfer the users drive to their manager
# echo "Transferring Google Drive to manager on file"
# $gam user "$userEmail" transfer drive "$managerEmail"
# sleep 1
# printf "\n\n--/--\n\n"

# Delegate the inbox to their manager
echo "Delegating inbox to manager"
$gam user "$userEmail" delegate to "$managerEmail"
sleep 0.5
printf "\n\n--/--\n\n"

# Set calendar event for admin to suspend & archive user after 90 days
echo "Setting calendar reminder for admin"
$gam user "$itCal" create event summary "Suspend & Archive $userEmail" start allday "$ninetyDays" end allday "$ninetyDays" reminder 1 email
sleep 0.5
printf "\n\n--/--\n\n"

# # Suspend user
# echo "Suspending the user"
# $gam update user "$userEmail" suspended on
# sleep 2
# printf "\n\n--/--\n\n"

# # Archive user
# echo "Archiving the user"
# $gam update user "$userEmail" archive on
# sleep 0.5
# printf "\n\n--/--\n\n"

# Move users to corresponding Archived OU
if [[ "$userType" == "Contractor" || "$userType" == "contractor" ]]; then
  echo "Moving user to Archived Contractors OU"
  $gam update user "$userEmail" ou "/Contractors/Archived Contractors"
else
  echo "Moving user to Archived Employees OU"
  $gam update user "$userEmail" ou "/Employees/Archived Employees"
fi

printf "\n\n--FIN--\n\n"
}

###########################
###### DO THE THINGS ######
###########################

# Create user logfile
echo "Creating log file"
touch "$logFile"

# Quick heads up
printf "Offboard process starting... \n\nThis may take longer than expected so please keep the terminal window open. \nA message will confirm once complete."

# Run the function and add output to logFile
offboard "$@" >> "$logFile" 2>&1

echo "Almost there..."

###########################
## MV FOLDER TO IT DRIVE ##
###########################

# Python script variables
sharedDriveId="<sharedDriveId>"
destinationFolderId="<sharedDriveFolderId>"
credentialsFile="$HOME/.gam/<credentialsFile.json>"
pyScript="$HOME/.gam/<pythonFile.py>"

# Confirm if py script exists
if [[ -f "$pyScript" ]]; then
    # Run the Python script 
    python "$pyScript" "$userPath" "$sharedDriveId" "$destinationFolderId" "$credentialsFile"
    printf "\n\n--/--\n\n"
else
    printf "Process complete! Please check user offboarding folder in your local home directory.\n\n"
    printf "\n\n--/--\n\n"
fi

exit 0
