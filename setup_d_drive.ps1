# IMAS Environment Setup
$cacheDir = "D:\IMAS_Build_Cache"
$pubCache = "D:\IMAS_Build_Cache\pub-cache"
$gradleCache = "D:\IMAS_Build_Cache\gradle"
$tempCache = "D:\IMAS_Build_Cache\temp"

# Create Folders
if (-not (Test-Path $cacheDir)) { New-Item -Path $cacheDir -ItemType Directory }
if (-not (Test-Path $pubCache)) { New-Item -Path $pubCache -ItemType Directory }
if (-not (Test-Path $gradleCache)) { New-Item -Path $gradleCache -ItemType Directory }
if (-not (Test-Path $tempCache)) { New-Item -Path $tempCache -ItemType Directory }

# Set Environment
$env:PUB_CACHE = $pubCache
$env:GRADLE_USER_HOME = $gradleCache
$env:TEMP = $tempCache
$env:TMP = $tempCache

# Add Flutter to Path
$fPath = "D:\IMAS-Frontend Development\flutter_windows_3.27.4-stable\flutter\bin"
if ($env:Path -notlike "*$fPath*") { $env:Path = "$fPath;$env:Path" }

Write-Host "D-Drive Redirection Active"
Write-Host "Run: flutter run"
