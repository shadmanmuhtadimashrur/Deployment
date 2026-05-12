param (
[Parameter(Mandatory=$true)]
[string]$SourcePath   # <-- Now this is a folder, not zip   make sure source folder named as angular & publish-phub
)


function Confirm-Step($stepName) {
    $response = Read-Host "`nDo you want to proceed to next step after [$stepName]? (Y/N)"
    
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Execution stopped by user." -ForegroundColor Yellow
        exit 0
    }
}

# ---- CONFIGURATION ----
Import-Module WebAdministration -ErrorAction Stop
$appPath     = "D:\peoplehubApp"
$apiPath     = "D:\peoplehubApi"
$backupRoot  = "D:\backup"

$appService  = "PeopleHubApp"
$apiService  = "PeopleHubApi"

# -----------------------

$date         = Get-Date -Format "ddMMyyyy"
$backupFolder = Join-Path $backupRoot $date

function Log($msg) {
Write-Host "`n==> $msg" -ForegroundColor Cyan
}

# ---- STEP 1: Validate source folder exists ----

if (-not (Test-Path $SourcePath)) {
Write-Host "ERROR: Source folder not found: $SourcePath" -ForegroundColor Red
exit 1
}
# ---- STEP 2: Stop services ----
Log "Stopping services..."
Stop-Website -Name $apiService -Force -ErrorAction Stop
Stop-Website -Name $appService -Force -ErrorAction Stop
Write-Host "Services stopped." -ForegroundColor Green
Confirm-Step "Stopping services"

# ---- STEP 3: Backup current deployment ----

Log "Backing up current deployment to $backupFolder ..."
New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
Copy-Item -Path $appPath -Destination "$backupFolder\peoplehubApp" -Recurse -Force
Copy-Item -Path $apiPath -Destination "$backupFolder\peoplehubApi" -Recurse -Force
Write-Host "Backup complete." -ForegroundColor Green
Confirm-Step "Backup"
# ---- STEP 4: Clean deployment folders ----

Log "Cleaning deployment folders..."

Get-ChildItem -Path $appPath -Recurse | Remove-Item -Recurse -Force

Get-ChildItem -Path $apiPath -Recurse |
Where-Object { $_.Name -ne "appsettings.json" } |
Remove-Item -Recurse -Force

Write-Host "Folders cleaned." -ForegroundColor Green
Confirm-Step "Cleaning folders"
# ---- STEP 5: Copy new files (from extracted folder) ----

Log "Copying new build files..."

Copy-Item -Path "$SourcePath\angular\*" -Destination $appPath -Recurse -Force
Copy-Item -Path "$SourcePath\publish-phub\*"  -Destination $apiPath  -Recurse -Force

Write-Host "Files copied." -ForegroundColor Green
Confirm-Step "Copying files"
# ---- STEP 7: Start services ----
Log "Starting services..."
Start-Website -Name $appService
Start-Website -Name $apiService
Write-Host "Services started." -ForegroundColor Green

Write-Host "`n[DONE] Deployment completed successfully. Backup saved to: $backupFolder" -ForegroundColor Yellow
