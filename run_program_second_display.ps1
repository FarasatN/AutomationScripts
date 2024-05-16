[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
# *********************************************************************************


# # #1. Define the file path of the app
# $appPath = "D:\after format\QMS-NEW_\QMSPRO Kiosk.exe"
# $appPath = "D:\after format\QMS-NEW_\QMSPRO Operator.exe"
$appPath = "D:\after format\CashExpert KeyGen.exe"


$appProcess = Start-Process -FilePath $appPath -PassThru
# # # # Wait for the application window to be created
Start-Sleep -Seconds 4

# # Find the application window by process ID
# $app = Get-Process -Id $appProcess.Id | ForEach-Object { $_.MainWindowHandle }


# # Define the process ID of the application
$processId = 5652 # Replace with the actual process ID

# Get the process associated with the specified process ID
$process = Get-Process -Id $appProcess.Id -ErrorAction SilentlyContinue
# $process = Get-Process -Id 5652 -ErrorAction SilentlyContinue

# Check if the process exists and has a main window handle
if ($process -and $process.MainWindowHandle.ToInt32() -ne 0) {
    # Check if the User32 type is already defined
    if (-not ([System.Management.Automation.PSTypeName]'User32').Type) {
    # Load the user32.dll library

        Add-Type @"
        using System;
        using System.Runtime.InteropServices;

        public class User32 {
            [DllImport("user32.dll")]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

            [DllImport("user32.dll")]
            public static extern bool MoveWindow(IntPtr hWnd, int x, int y, int width, int height, bool repaint);

            [DllImport("user32.dll", SetLastError = true)]
            public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

            [DllImport("user32.dll", SetLastError = true)]
            public static extern IntPtr GetForegroundWindow();

            [StructLayout(LayoutKind.Sequential)]
            public struct RECT {
                public int Left;
                public int Top;
                public int Right;
                public int Bottom;
            }
        }
"@
    }
    

    # Get the handle of the application window
    $hWnd = $process.MainWindowHandle.ToInt32()

    # Get the second monitor
    $secondMonitor = [System.Windows.Forms.Screen]::AllScreens | Where-Object { $_.Primary -eq $false }

    # Check if a second monitor is available
    if ($secondMonitor) {
        # Get the dimensions of the second monitor
        $secondMonitorWidth = $secondMonitor.Bounds.Width
        $secondMonitorHeight = $secondMonitor.Bounds.Height

        # Move the application window to the second monitor
        [User32]::MoveWindow($hWnd, $secondMonitor.Bounds.Left, $secondMonitor.Bounds.Top, $secondMonitorWidth, $secondMonitorHeight, $true)
    } else {
        Write-Host "Second monitor not found."
    }
} else {
    Write-Host "Application window not found for process ID $processId."
}










# -------------------------------------


#Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams
# $count = [System.Windows.Forms.Screen]::allscreens.length

# $displays = Get-CimInstance -Namespace root\cimv2 -ClassName Win32_DesktopMonitor

# $displays[1].SetPrimary()


# $secondMonitorWidth = $secondMonitor.ScreenWidth
# $secondMonitorHeight = $secondMonitor.ScreenHeight
# $screencount = [System.Windows.Forms.Screen]::allscreens.length
# $ScreenArray = @()
# For ($i = 0; $i -lt $screencount; $i++)
#      {
#     If ([System.Windows.Forms.Screen]::allscreens.get($i).Primary -ne $true) 
#         {
#         $ScreenArray += [System.Windows.Forms.Screen]::allscreens.get($i)
#         }
#     }
    



#-------------------------
# Set the specified display as primary using the Display Configuration API

# $displayConfiguration = New-Object -ComObject WScript.Shell
# $displayConfiguration.Run("DisplaySwitch.exe /internal")
# Start-Sleep -Seconds 1
# $displayConfiguration.SendKeys("{TAB}{TAB}{TAB}{ENTER}")
# Start-Sleep -Seconds 1
# $displayConfiguration.SendKeys("{DOWN}{ENTER}")
# Start-Sleep -Seconds 1
# $displayConfiguration.SendKeys("{TAB}{TAB}{TAB}{ENTER}")
# Start-Sleep -Seconds 1
# $displayConfiguration.SendKeys("{ENTER}")




