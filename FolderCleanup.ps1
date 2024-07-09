# Start message
Write-Host "FolderCleanup process started.. "

#Define the days for deleting older folders:
$daysToBeDelete = 35

$driveLetter = "D"


# Define keywords to exclude
$excludeKeywords = @("Loan", "Cash", "Online") #excludeKeywords - nəzərə alınmayanlar(silinməməlilər)

#-------------------------------------------------------------------------------------------------------------------------------







# Define the root folder path
$rootPath = $driveLetter+":\Cameras"

# Define log file location
$logFile = $driveLetter+":\FolderCleanup.txt"







$linesToKeep = 2000

# Log function with error handling
function Log-Message {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    try {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
    } catch {
        Write-Host "Failed to write log entry: $logMessage"
        Write-Host "Error: $_"
    }
}

# Function to check if a folder name contains any of the exclude keywords
function ShouldExcludeFolder {
    param (
        [string]$folderName
    )
    try {
        foreach ($keyword in $excludeKeywords) {
            if ($folderName -like "*$keyword*") {
                return $true
            }
        }
        return $false
    } catch {
        Log-Message "Error checking folder exclusion: $folderName - $_" "ERROR"
        return $false
    }
}

# Function to permanently delete old date folders with error handling
function Delete-OldDateFolders {
    param (
        [string]$parentFolder
    )
    try {
        # Get today's date and calculate the date one month ago
        $today = Get-Date
        $someDaysAgo = $today.AddDays(-$daysToBeDelete)
        Log-Message "Checking for old date folders in: $parentFolder"

        # Get all subfolders matching date pattern YYYY-MM-DD
        $dateFolders = Get-ChildItem -Path $parentFolder -Directory -ErrorAction Stop | Where-Object {
            $_.Name -match '^\d{4}-\d{2}-\d{2}$'
        }

        foreach ($folder in $dateFolders) {
            try {
                $folderDate = [datetime]::ParseExact($folder.Name, 'yyyy-MM-dd', $null)
                if ($folderDate -lt $someDaysAgo) {
                    Remove-Item -Path $folder.FullName -Force -Recurse -ErrorAction Stop
                    Log-Message "Deleted folder: $($folder.FullName)"
                }
            } catch {
                Log-Message "Error processing folder: $($folder.FullName) - $_" "ERROR"
            }
        }
    } catch {
        Log-Message "Error accessing parent folder: $parentFolder - $_" "ERROR"
    }
}

# Start logging
Log-Message "Starting folder cleanup process."

try {
    # Get all folders in the root path
    $folders = Get-ChildItem -Path $rootPath -Directory -ErrorAction Stop
    Log-Message "Retrieved all folders in root path: $rootPath"

    # Step 1: Log skipped folders
    foreach ($folder in $folders) {
        $folderName = $folder.Name
        if (ShouldExcludeFolder -folderName $folderName) {
            Log-Message "Skipping folder: $($folder.FullName)"
        }
    }

    # Step 2: Process remaining folders
    foreach ($folder in $folders) {
        $folderName = $folder.Name
        if (-not (ShouldExcludeFolder -folderName $folderName)) {
            Log-Message "Entering and processing folder: $($folder.FullName)"
            Delete-OldDateFolders -parentFolder $folder.FullName
        }
    }
} catch {
    Log-Message "Critical error during folder cleanup process: $_" "ERROR"
}

# End logging
Log-Message "Completed folder cleanup process."

try {
    # Read the file
    $logContent = Get-Content -Path $logFile -ErrorAction Stop
    Write-Host "Log file read successfully."

    # Get the last $linesToKeep lines
    if ($logContent.Count -gt $linesToKeep) {
        $logContent = $logContent[-$linesToKeep..-1]
        Write-Host "Truncated log content to the last $linesToKeep lines."
    }

    # Write the truncated content back to the log file
    Set-Content -Path $logFile -Value $logContent -ErrorAction Stop
    Write-Host "Truncated log content written back to log file successfully."
} catch {
    Write-Host "An error occurred: $_"
}


# End message
Write-Host "FolderCleanup process completed. "


# Sleep for half a second
Start-Sleep -Milliseconds 500  
