import os
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

###########################
###### SET VARIABLES ######
###########################

userPath = sys.argv[1]
sharedDriveId = sys.argv[2]
destinationFolderId = sys.argv[3]
credentialsFile = sys.argv[4]

###########################
####### DO THE DEW ########
###########################

def moveFolderToSharedDrive(userPath, sharedDriveId, destinationFolderId, credentialsFile):
    # Load credentials from JSON file
    credentials = service_account.Credentials.from_service_account_file(
        credentialsFile, scopes=["https://www.googleapis.com/auth/drive"]
    )

    # Create Google Drive API client
    driveService = build("drive", "v3", credentials=credentials)

    # Check if the shared drive exists
    response = driveService.drives().get(driveId=sharedDriveId).execute()
    if "id" not in response:
        raise ValueError(f"Shared drive with ID '{sharedDriveId}' not found.")

    # Check if the destination folder exists within the shared drive
    response = driveService.files().get(
        fileId=destinationFolderId,
        supportsAllDrives=True,
        fields="id",
    ).execute()
    if "id" not in response:
        raise ValueError(f"Destination folder with ID '{destinationFolderId}' not found in the shared drive.")

    # Create a new folder in the destination folder
    sourceFolderName = os.path.basename(userPath)
    folderMetadata = {
        "name": sourceFolderName,
        "parents": [destinationFolderId],
        "mimeType": "application/vnd.google-apps.folder"
    }
    newFolder = driveService.files().create(
        body=folderMetadata,
        supportsAllDrives=True,
        fields="id"
    ).execute()
    newFolderId = newFolder.get("id")

    # Upload files from the local folder to the new folder
    for root, dirs, files in os.walk(userPath):
        for file in files:
            filePath = os.path.join(root, file)
            media = MediaFileUpload(filePath)
            fileMetadata = {"name": file, "parents": [newFolderId]}
            driveService.files().create(
                body=fileMetadata,
                media_body=media,
                supportsAllDrives=True,
                fields="id",
            ).execute()

    print("Process complete! Please check user offboarding folder in the IT Shared Drive for more info.")

if __name__ == "__main__":
    moveFolderToSharedDrive(userPath, sharedDriveId, destinationFolderId, credentialsFile)
