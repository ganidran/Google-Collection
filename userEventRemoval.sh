#!/bin/bash

###########################
###### CHECK FOR DIRS #####
###########################

# Creating an 'CalendarRemoval' folder if it doesn't exist
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

 # Define expression pattern for date validation
datePattern='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'

# Prompt for date input
while true; do
    read -r -p "Delete all events after this date (YYYY-MM-DD format): " offDate

    # Validate date format
    if [[ $offDate =~ $datePattern ]]; then
        break
    else
        printf "Error: Invalid date format. Please enter a date in YYYY-MM-DD format.\n\n"
    fi
done

# User is valid, proceed with script
printf "\nEmail: %s is a valid format. Date: %s is the valid format.\n\n" "$userEmail" "$offDate"

# Confirm user's choice
read -r -p "Are you sure you want to proceed with removing user '$userEmail' as attendee from all events after $offDate? (y/n) " confirm
if [[ "$confirm" != "y" ]]; then
    printf "Operation cancelled.\n\n"
    exit 1
else
    printf "Removing  %s...\n\n" "$userEmail calendar items"
fi

sleep 1

###########################
#### SETTING VARIABLES ####
###########################

# Today's date
today=$(date +%Y-%m-%d)
# Gam binary path
gam="$HOME/bin/gamadv-xtd3/gam"
# Log file
logFile=$userPath/logFile-calEvents-"$today".txt
# Offboarded user folder path
userPath=$HOME/Offboarded/$userEmail
# Managed mobile device list
calEventList="$userPath"/calEvents-"$today".csv

###########################
###### DO THE THINGS ######
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


operation() {
printf "\n\n--START--\n\n"

# Unarchiving user if archived
echo "Unarchiving the user"
$gam update user "$userEmail" archive off
sleep 1
printf "\n\n--/--\n\n"

# Unsuspending user if archived
echo "Unsuspending the user"
$gam update user "$userEmail" suspended off
sleep 1
printf "\n\n--/--\n\n"

# Grab all events
echo "Grabbing all Calendar events"
$gam calendar "$userEmail" print events after "$offDate" fields organizer.email,recurringEventId,summary,created,status > "$calEventList"
sleep 1
printf "\n\n--/--\n\n"

# Remove user from these events
echo "Removing user from normal events."
$gam csv "$calEventList" gam calendar ~organizer.email update event id ~id removeattendee "$userEmail"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing user from recurring events."
$gam csv "$ucalEventList" gam calendar ~organizer.email update event id ~recurringEventId removeattendee "$userEmail"
sleep 1
printf "\n\n--/--\n\n"

# Last bit of removal
echo "Removing remaining events from primary calendar view"
$gam calendar "$userEmail" delete events after "$offDate" doit sendnotifications false

printf "\n\n--/--\n\n"
}

# Create user logfile
echo "Creating log file"
touch "$logFile"

# Quick heads up
echo "Event removal process starting. This will take some time so please keep the terminal window open until complete..."

# Run the function and add output to logFile
operation "$@" >> "$logFile" 2>&1

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
