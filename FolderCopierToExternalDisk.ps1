
# Set console background to white and text color to blue
$host.UI.RawUI.BackgroundColor = "White"
$host.UI.RawUI.ForegroundColor = "Blue"
Clear-Host

# Define a global variable
$Global:pathAccessable = $true
$Global:logFile = ""
$Global:logFileBackground = ""
$Global:networkPath = ""
$Global:destinationDriveLetter = ""
# Define the path for the shared file
# $Global:sharedFilePath = ""

# Log function with error handling
function LogMessage {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    try {
        Add-Content -Path $Global:logFile -Value $logMessage -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to write log entry: $logMessage"
        Write-Host "Error: $_"
    }
}

# Start message
Write-Host "Folder creation and file copying process started.. "
LogMessage "Folder creation and file copying process started.."

# Function to get and validate the drive letter from the user
function GetValidDriveLetter {
    param (
        [string]$promptMessage
    )
    while ($true) {
        $driveLetter = Read-Host $promptMessage
        if ([string]::IsNullOrWhiteSpace($driveLetter)) {
            Write-Host "Drive letter cannot be empty or whitespace. Exiting script."
            LogMessage "Drive letter name cannot be empty or whitespace. Exiting script." "ERROR"
        }
        else {
            $driveLetter = $driveLetter.Trim()
            if (Test-Path -Path $($driveLetter + ":\")) {
                return $driveLetter
            }
            else {
                Write-Host "The provided drive letter does not exist. Please try again."
                LogMessage "The provided drive letter does not exist. Please try again."
            }
        }
    }
}
# Function to create folder
function CreateFolder {
    param (
        [int]$shouldLog = 1,
        [string]$folderName,
        [string]$targetPath
    )
    $newFolderPath = Join-Path -Path $targetPath -ChildPath $folderName
    if ($shouldLog -eq 0) {
        if (-not (Test-Path -Path $newFolderPath)) {
            try {
                New-Item -Path $newFolderPath -ItemType Directory -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "An error occurred while creating the folder: $_"
                LogMessage "An error occurred while creating the folder: $_" "ERROR"
            }
        }
    }
    else {
        if (-not (Test-Path -Path $newFolderPath)) {
            try {
                New-Item -Path $newFolderPath -ItemType Directory -ErrorAction Stop | Out-Null
                Write-Host "Created folder: $newFolderPath"
                LogMessage "Created folder: $newFolderPath"
            }
            catch {
                Write-Host "An error occurred while creating the folder: $_"
                LogMessage "An error occurred while creating the folder: $_" "ERROR"
            }
        }
        else {
            Write-Host "Folder already exists: $newFolderPath"
            LogMessage "Folder already exists: $newFolderPath"
        }
    }
}
# Function to check if folder name matches subfolder name
function FolderMatched {
    param (
        [string]$folderName
    )
    foreach ($keyword in $subFolderName) {
        if ($folderName -like "*$keyword*") {
            Write-Host "Searched folder matched!"
            LogMessage "Searched folder matched!"
            return $true
        }
    }
    return $false
}

# Function to copy subfolders from source to destination
function CopySubfolders {
    param (
        [string]$sourcePath,
        [string]$destinationPath
    )
    if (-not (Test-Path -Path $destinationPath)) {
        try {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
        }
        catch {
            Write-Host "An error occurred while creating the destination folder: $_"
            LogMessage "An error occurred while creating the destination folder: $_" "ERROR"
            return
        }
    }
    try {
        Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force -ErrorAction Stop
        Write-Host "Successfully copied folder and subfolders from '$sourcePath' to '$destinationPath'."
        LogMessage "Successfully copied folder and subfolders from '$sourcePath' to '$destinationPath'."
        $Global:pathAccessable = $true
        return $true
    }
    catch {
        Write-Host "An error occurred while copying subfolders: $_"
        LogMessage "An error occurred while copying subfolders: $_" "ERROR"
        $Global:pathAccessable = $false
        return $false
    }
}
function RepeatProcess {
    $allCopyTasks = @()
    do {
        # Get destination drive letter from user
        $Global:destinationDriveLetter = GetValidDriveLetter -promptMessage "Enter the destination drive letter (e.g., E, F, G)"
        $externalDrivePath = $(($Global:destinationDriveLetter.Trim()) + ":\")
        $Global:logFile = $($Global:destinationDriveLetter + ":\FolderCopierToExternalDiskLog.txt")
        Write-Host "Log file created at $Global:logFile"
        LogMessage "Log file created at $Global:logFile"

        # Input network path from user
        $Global:networkPath = Read-Host "Enter the network path to search for matching folders (e.g., \\abc-k3\Cameras)"

        if ([string]::IsNullOrWhiteSpace($Global:networkPath)) {
            Write-Host "Network path cannot be empty or whitespace. Exiting script."
            LogMessage "Network path cannot be empty or whitespace. Exiting script." "ERROR"
            exit
        }
        else {
            $Global:networkPath = $Global:networkPath.Trim().ToLower()
        }

        $storeName = ""
        if (-not (Test-Path -Path $Global:networkPath)) {
            Write-Host "The provided network path does not exist. Exiting script."
            LogMessage "The provided network path does not exist. Exiting script." "ERROR"
            exit
        }
        else {
            $storeName = ($Global:networkPath.Trim().Substring(2)).Split('\')[0]
        }

        # Input main folder name from user
        $mainFolderName = Read-Host "Enter the main folder name (e.g., client name) you want to create on the external disk"
        if ([string]::IsNullOrWhiteSpace($mainFolderName)) {
            Write-Host "Main folder name (e.g., client name) cannot be empty or whitespace. Exiting script."
            LogMessage "Main folder name (e.g., client name) cannot be empty or whitespace. Exiting script." "ERROR"
            exit
        }
        else {
            $mainFolderName = $mainFolderName.Trim()
        }

        # Create the main folder
        CreateFolder -shouldLog 0 -folderName $mainFolderName -targetPath $externalDrivePath
        $mainFolderPath = Join-Path -Path $externalDrivePath -ChildPath $mainFolderName
        # Create folder with store name in main folder, then subfolder inside it
        CreateFolder -folderName $storeName -targetPath $mainFolderPath
        $storeFolderPath = Join-Path -Path $mainFolderPath -ChildPath $storeName

        # Input subfolder name from user
        $subFolderName = Read-Host "Enter the subfolder (camera folder) name you want to create inside the main folder"
        if ([string]::IsNullOrWhiteSpace($subFolderName)) {
            Write-Host "Subfolder (camera folder) name cannot be empty or whitespace. Exiting script."
            LogMessage "Subfolder (camera folder) name cannot be empty or whitespace. Exiting script." "ERROR"
            exit
        }
        else {
            $subFolderName = $subFolderName.Trim()
        }

        # Create the subfolder inside the main folder
        CreateFolder -folderName $subFolderName -targetPath $storeFolderPath

        # Input start and end dates from user
        $startDate = Read-Host "Enter the start date (YYYY-MM-DD)"
        $endDate = Read-Host "Enter the end date (YYYY-MM-DD)"
        if (([string]::IsNullOrWhiteSpace($startDate)) -or ([string]::IsNullOrWhiteSpace($endDate))) {
            Write-Host "Subfolder (camera folder) name cannot be empty or whitespace. Exiting script."
            LogMessage "Subfolder (camera folder) name cannot be empty or whitespace. Exiting script." "ERROR"
            exit
        }
        else {
            $startDate = $startDate.Trim()
            $endDate = $endDate.Trim()
        }
        
        try {
            $startDate = [datetime]::ParseExact($startDate, 'yyyy-MM-dd', $null)
            $endDate = [datetime]::ParseExact($endDate, 'yyyy-MM-dd', $null)
        }
        catch {
            Write-Host "Invalid date format. Exiting script."
            LogMessage "Invalid date format. Exiting script." "ERROR"
            exit
        }

        # Get all folders in the network path
        try {
            $matchingFolders = Get-ChildItem -Path $Global:networkPath -Directory -ErrorAction Stop
            Write-Host "Retrieved all folders in network path: $Global:networkPath"
            LogMessage "Retrieved all folders in network path: $Global:networkPath"
        }
        catch {
            Write-Host "Error retrieving folders in network path: $_"
            LogMessage "Error retrieving folders in network path: $_" "ERROR"
            exit
        }

        $copyTasks = @()
        foreach ($folder in $matchingFolders) {
            if (FolderMatched -folderName $folder.Name) {
                Write-Host "Matched folder: $($folder.FullName)"
                LogMessage "Matched folder: $($folder.FullName)"

                $matchedFoldersNetworkPath = Join-Path -Path $Global:networkPath -ChildPath $folder.Name
                if (-not (Test-Path -Path $matchedFoldersNetworkPath)) {
                    Write-Host "The provided network path does not exist in matched folder. Exiting script."
                    LogMessage "The provided network path does not exist in matched folder. Exiting script." "ERROR"
                    exit
                }

                try {
                    $matchedSubfolders = Get-ChildItem -Path $matchedFoldersNetworkPath -Directory -ErrorAction Stop
                }
                catch {
                    Write-Host "Error retrieving subfolders in matched folder: $_"
                    LogMessage "Error retrieving subfolders in matched folder: $_" "ERROR"
                    continue
                }
                foreach ($subfolder in $matchedSubfolders) {
                    try {
                        $folderDate = [datetime]::ParseExact($subfolder.Name, 'yyyy-MM-dd', $null)
                        if ($folderDate -ge $startDate -and $folderDate -le $endDate) {
                            Write-Host "Will copy folder: $($subfolder.FullName)"
                            LogMessage "Will copy folder: $($subfolder.FullName)"
                            $destinationPath = Join-Path -Path $storeFolderPath -ChildPath $folder.Name
                            $copyTasks += [PSCustomObject]@{
                                Source      = $subfolder.FullName
                                Destination = $destinationPath
                            }
                        }
                    }
                    catch {
                        Write-Host "Error processing folder: $($subfolder.FullName) - $_" "ERROR"
                        LogMessage "Error processing folder: $($subfolder.FullName) - $_" "ERROR"
                    }
                }
                break
            }
        }

        $allCopyTasks += $copyTasks

        # Ask if the user wants to copy another folder
        $continue = Read-Host "Do you want to copy another folder? ( yes(y) / no(n) or any keyword )"
        if ([string]::IsNullOrWhiteSpace($continue) -or $continue -eq "no" -or $continue -eq "n") {
            Write-Host "Entered keyword : $continue"
            LogMessage "Entered keyword : $continue"
            break
        }
        else {
            $continue = $continue.Trim().ToLower()
        }
        # Optionally, include other processing here if needed
        # Simulate a pause
        Start-Sleep -Seconds 1
    } while ($true)

    Write-Host "all tasks  : $($allCopyTasks)"
    LogMessage "all tasks  : $($allCopyTasks)"
    
    #***********************************************
    $timerElapsedScript = {
        ScheduleNetworkPathCheck -networkPath $Global:networkPath
    }
    # Create a Timer object
    $timer = New-Object System.Timers.Timer
    $timer.Interval = 2000  # Set interval to 1000 milliseconds (1 second)
    $timer.AutoReset = $true
    $timer.Enabled = $false  # Initially disable the timer
    # Define the Timer Elapsed event action
    

    foreach ($task in $allCopyTasks) {
        Write-Host "current task  : $($task)"
        LogMessage "current task  : $($task)"
        $Global:networkPath = $task.Source
        Write-Host "current path  : $($Global:networkPath)"
        LogMessage "current path  : $($Global:networkPath)"
        # Register the Timer Elapsed event
        $timer.Enabled = $true    
        $eventSubscription = Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action $timerElapsedScript # -ArgumentList $task.Source
        # Check the path access status
        if ($Global:pathAccessable -eq $false) {
            Write-Host "pathAccessable value : $Global:pathAccessable, skipped to next task.."
            LogMessage "pathAccessable value : $Global:pathAccessable,  skipped to next task.."
            # Disable the timer to prevent further checks
            # $timer.Enabled = $false
            continue
        }
        else {
            # Copying process started..
            Write-Host "Current copying task : $($task)"
            LogMessage "Current copying task  : $($task)"
            $isSuccesfull = CopySubfolders -sourcePath $task.Source -destinationPath $task.Destination
            if ($isSuccesfull -eq $false) {
                # Continue to next task
                # $timer.Enabled = $false
                continue
            }
            else {
                Write-Host "Task completed successfully."
                LogMessage "Task completed successfully."
                # Stop the timer and dispose
                $timer.Enabled = $false
                $timer.Stop()
                $timer.Dispose()
            }
        }
    }
    
    # Cleanup: Unregister the event
    # Unregister-Event -SourceIdentifier TimerElapsedEvent
    Unregister-Event -SubscriptionId $eventSubscription.Id
    $timer.Enabled = $false
    $timer.Stop()
    $timer.Dispose()

    # foreach ($task in $allCopyTasks) {
    #     Write-Host "current task  : $($task)"
    #     LogMessage "current task  : $($task)"
    #     $timerElapsedScript = {
    #         ScheduleNetworkPathCheck -networkPath $task.Source
    #     }
    #     # Register the Timer Elapsed event and get the event subscription ID
    #     Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action $timerElapsedScript

    #     if ($Global:pathAccessable -eq $false) {
    #         Write-Host "pathAccessable value : $Global:pathAccessable, skipped to next task.."
    #         LogMessage "pathAccessable value : $Global:pathAccessable,  skipped to next task.."
    #         continue
    #     }
    #     else {
    #         # Copying process started..
    #         Write-Host "Current copying task : $($task)"
    #         LogMessage "Current copying task  : $($task)"
    #         $isSuccesfull = CopySubfolders -sourcePath $task.Source -destinationPath $task.Destination
    #         if ($isSuccesfull -eq $false) {
    #             continue
    #         }
    #         Write-Host "before stop in else"
    #         LogMessage "before stop in else"
    #         # Cleanup: Stop the timer and unregister the event
    #         # Unregister-Event -SourceIdentifier $eventSubscription.Id
    #         $timer.Stop()
    #         $timer.Dispose()
    #     }
    #     Write-Host "before stop"
    #     LogMessage "before stop"
    #     # Cleanup: Stop the timer and unregister the event
    #     # Unregister-Event -SourceIdentifier $eventSubscription.Id
    #     $timer.Stop()
    #     $timer.Dispose()
       
    # }

    #***********************************************


    # End logging
    Write-Host "Folder creation and file copying process completed."
    LogMessage "Folder creation and file copying process completed."

    # Reset console colors
    $host.UI.RawUI.BackgroundColor = "Black"
    $host.UI.RawUI.ForegroundColor = "White"
    Clear-Host


}



# Function to check if network folder path is accessible
function CheckNetworkPath {
    param (
        [string]$Global:networkPath
    )
    # $Global:networkPath = "\\abc-k3\CamerasS"
    try {
        $exists = Test-Path -Path $Global:networkPath 
        if ($exists) {
            Write-Host "Network path '$Global:networkPath' is accessible."
            LogMessage "Network path '$Global:networkPath' is accessible."
            return $true
        }
        else {
            Write-Host "Network path '$Global:networkPath' is not accessible."
            LogMessage "Network path '$Global:networkPath' is not accessible."
            return $false
        }
    }
    catch {
        Write-Host "Error accessing network path '$Global:networkPath': $_"
        LogMessage "Error accessing network path '$Global:networkPath': $_"
        return $false
    }
}

# Function to schedule periodic checks
function ScheduleNetworkPathCheck {
    param (
        [string]$Global:networkPath
    )
    # Infinite loop for periodic checking
    while ($true) {
        try {
            $checkValue = CheckNetworkPath -networkPath $Global:networkPath
            if ($checkValue -eq $true) {
                $Global:pathAccessable = $true
                Write-Host "Path status: '$Global:pathAccessable'"
                Write-Host "Network path '$Global:networkPath' is accessible."
                LogMessage "Path status: $Global:pathAccessable"
                LogMessage "Network path '$Global:networkPath' is accessible."
            }
            else {
                $Global:pathAccessable = $false
                Write-Host "Path status: $Global:pathAccessable"
                Write-Host "Network path '$Global:networkPath' is not accessible. Retrying..."
                LogMessage "Path status: $Global:pathAccessable"
                LogMessage "Network path '$Global:networkPath' is not accessible. Retrying..."
            }
        }
        catch {
            $Global:pathAccessable = $false
            Write-Host "Error when checking '$Global:networkPath': $_"
            LogMessage "Error when checking '$Global:networkPath': $_"
        }
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "$timestamp - Network path status: $Global:PathAccessible"   
        LogMessage "$timestamp - Network path status: $Global:PathAccessible"
        Start-Sleep -Seconds 2 # Wait for 2 seconds before next check
    }
}




# Start the repeat process
RepeatProcess
#--------------------------------------------








# Write-Host "$Global:networkPath, $Global:pathAccessable, $externalDrivePath, $Global:logFileBackground"
# LogMessage "$Global:networkPath, $Global:pathAccessable, $externalDrivePath, $Global:logFileBackground"
# $networkJob = Start-Job -ScriptBlock {
#     param (
#         $Global:networkPath,
#         $Global:pathAccessable,
#         $Global:destinationDriveLetter,
#         $Global:logFileBackground
#     )
#     Write-Host "background process works...."
#     LogMessage "background process works...."

#     # function LogMessage {
#     #     param (
#     #         [string]$message,
#     #         [string]$level = "INFO"
#     #     )
#     #     $Global:logFileBackground = $Global:destinationDriveLetter + ":\CheckingSourceBackground.txt"
#     #     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#     #     $logMessage = "$timestamp [$level] - $message"
#     #     try {
#     #         Add-Content -Path $Global:logFileBackground -Value $logMessage -ErrorAction Stop
#     #     }
#     #     catch {
#     #         Write-Host "Failed to write log entry: $logMessage"
#     #         Write-Host "Error: $_"
#     #     }
#     # }
#     function CheckNetworkPath {
#         param (
#             [string]$Global:networkPath
#         )
#         $Global:networkPath = "\\abc-k3\CamerasS"
#         try {
#             $exists = Test-Path -Path $Global:networkPath -PathType Container -ErrorAction Stop
#             if ($exists) {
#                 Write-Host "Network path '$Global:networkPath' is accessible."
#                 LogMessage "Network path '$Global:networkPath' is accessible."
#                 return $true
#             }
#             else {
#                 Write-Host "Network path '$Global:networkPath' is not accessible."
#                 LogMessage "Network path '$Global:networkPath' is not accessible."
#                 return $false
#             }
#         }
#         catch {
#             Write-Host "Error accessing network path '$Global:networkPath': $_"
#             LogMessage "Error accessing network path '$Global:networkPath': $_"
#             return $false
#         }
#     }
#     function ScheduleNetworkPathCheck {
#         param (
#             [string]$Global:networkPath,
#             [string]$Global:sharedFilePath
#         )
#         while ($true) {
#             try {
#                 $checkValue = CheckNetworkPath -networkPath $Global:networkPath
#                 if ($checkValue -eq $true) {
#                     $Global:pathAccessable = $checkValue
#                     Write-Host "Path status: $Global:pathAccessable"
#                     Write-Host "Network path '$Global:networkPath' is accessible."
#                     LogMessage "Path status: $Global:pathAccessable"
#                     LogMessage "Network path '$Global:networkPath' is accessible."
#                 }
#                 else {
#                     $Global:pathAccessable = $checkValue
#                     Write-Host "Path status: $Global:pathAccessable"
#                     Write-Host "Network path '$Global:networkPath' is not accessible. Retrying..."
#                     LogMessage "Path status: $Global:pathAccessable"
#                     LogMessage "Network path '$Global:networkPath' is not accessible. Retrying..."
#                 }
#             }
#             catch {
#                 Write-Host "Error when writing content to shared file: $_"
#                 LogMessage "Error when writing content to shared file: $_"
#             }
#             Start-Sleep -Seconds 2 # Wait for 5 seconds before next check
#         }
#     }
#     ScheduleNetworkPathCheck -networkPath $Global:networkPath
# } -ArgumentList $Global:networkPath, $Global:pathAccessable, $Global:destinationDriveLetter, $Global:logFileBackground, $Global:sharedFilePath
# Stop-Job -Job $networkJob
# Receive-Job -Job $networkJob
# Remove-Job -Job $networkJob -Force






