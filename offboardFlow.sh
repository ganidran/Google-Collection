#!/bin/bash

###########################
###### CHECK FOR DIRS #####
###########################

# Creating an 'Offboarding' folder if it doesn't exist
if [ -d "$HOME/Offboarding" ] 
then
    printf "Offboarding folder exists. Proceeding...\n\n" 
else
    printf "Offboarding folder doesn't exist. Creating...\n\n"
    mkdir "$HOME"/Offboarding
fi

# Checking for GAM
if [ -d "$HOME/bin/gam" ] 
then
    printf "Only basic GAM is installed. Please install GAM-ADV via: https://github.com/taers232c/GAMADV-XTD3/wiki/How-to-Upgrade-from-Standard-GAM or reset your Cloud Shell then follow our Wiki: https://www.notion.so/joinlevel/Setting-Up-GAM-6dedb55ef46747e8b30431978561a947 \n\n"
    exit 0
else
    printf "GAM is not installed. Please install it by following our Wiki: https://www.notion.so/joinlevel/Setting-Up-GAM-6dedb55ef46747e8b30431978561a947 \n\n"
    exit 0
fi

###########################
##### CHECK THE USER #####
###########################

# Define expression pattern for email validation
email_pattern='^[a-zA-Z0-9._%+-]+@level\.com$'

# Prompt for user email
while true; do
    read -r -p "Enter user email: " userEmail

    # Validate email format
    if [[ $userEmail =~ $email_pattern ]]; then
        break
    else
        printf "Error: Invalid email format or incorrect domain.\n\n"
    fi
done

# Get user type
userType=""

# Prompt for user type
while [[ "$userType" != "employee" && "$userType" != "Employee" && "$userType" != "contractor" && "$userType" != "Contractor" ]]; do

    read -r -p "Enter user type (contractor or employee): " userType

    # Check if user type is valid
    if [[ "$userType" != "employee" && "$userType" != "Employee" && "$userType" != "contractor" && "$userType" != "Contractor" ]]; then
        printf "Error: Invalid user type. Type 'Employee' or 'Contractor'.\n\n"
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

sleep 1

###########################
#### SETTING VARIABLES ####
###########################

# Gam binary path
gam="$HOME/bin/gamadv-xtd3/gam"
# Log file
logFile=log.txt
# Managed mobile device list
csvFile=mdmList.csv
# Offboarding user folder path
userPath=$HOME/Offboarding/$userEmail

###########################
###### DO THE THINGS ######
###########################

offboard() {
printf "\n\n--START--\n\n"

# Create folder for offboarding user
echo "Creating $userEmail folder"
mkdir "$userPath"
printf "\n\n--/--\n\n"

# Ouput only resourceIds of our 'csvFile'
echo "Creating list of managed mobile device resourceIds"
$gam config csv_output_header_filter "resourceId" redirect csv - > "$userPath"/"$csvFile" print mobile query "email:$userEmail"
sleep 0.5
printf "\n\n--/--\n\n"

# Remove user from all groups
echo "Removing user from Google Groups"
$gam user "$userEmail" delete groups
sleep 0.5
printf "\n\n--/--\n\n"

# Reset user's sign-in cookies & set a random pass
echo "Resetting sign-in cookies and setting a random password"
$gam user "$userEmail" signout
$gam update user "$userEmail" password random
sleep 0.5
printf "\n\n--/--\n\n"

# Remove connected applications, backup codes and/or tokens
echo "Removing connected apps, backup codes and/or tokens"
$gam user "$userEmail" deprovision
sleep 0.5
printf "\n\n--/--\n\n"

# Wipe account from managed devices
echo "Removing Google account from managed mobile device(s)"
$gam csv "$userPath"/"$csvFile" gam update mobile ~resourceId action account_wipe
sleep 2
printf "\n\n--/--\n\n"

# Remove devices from Google Workspace device management
echo "Removing managed mobile device(s) from Google MDM"
$gam csv "$userPath"/"$csvFile" gam delete mobile ~resourceId
sleep 0.5
printf "\n\n--/--\n\n"

# Suspend user
echo "Suspending the user"
$gam update user "$userEmail" suspended on
sleep 2
printf "\n\n--/--\n\n"

# Archive user
echo "Archiving the user"
$gam update user "$userEmail" archive on
sleep 0.5
printf "\n\n--/--\n\n"

# Move users to corresponding Archived OU
if [[ "$userType" == "Contractor" || "$userType" == "contractor" ]]; then
  echo "Moving user to Archived Contractors"
  $gam update user "$userEmail" ou "/Contractors/Archived Contractors"
else
  echo "Moving user to Archived Employees"
  $gam update user "$userEmail" ou "/Employees/Archived Employees"
fi

printf "\n\n--FIN--\n\n"
} 

# Run the function and add output to logFile
offboard "$@" 2>&1 | tee -- "$userPath"/"$logFile"

exit 0