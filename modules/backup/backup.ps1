# Cross-platform backup script for Windows PowerShell (3x-ui)

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$BACKUP_PATH
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\openssh-helper.ps1")

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $BACKUP_PATH) { $BACKUP_PATH = $env:BACKUP_PATH }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $BACKUP_PATH) {
  Write-Error "Error: Required parameters not set"
  exit 1
}

$backupDir = $BACKUP_PATH
if (-not (Test-Path $backupDir)) {
  New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$year = Get-Date -Format "yyyy"
$yearDir = Join-Path $backupDir $year
$remoteXui = "/home/$USER/x-ui"
$currentPath = Join-Path $backupDir "current"
$sshCommon = Get-SshCommonOptions -PrivateKeyPath $PRIVATE_KEY_PATH
$sshTarget = "$USER@${INSTANCE_IP}"

Write-Host "Backup directory: $backupDir"
Write-Host "Starting 3x-ui backup at $timestamp"

New-Item -ItemType Directory -Force -Path $yearDir | Out-Null

Invoke-OpenSshRemote -SshArguments ($sshCommon + @($sshTarget, "test -d $remoteXui"))

if (Test-Path $currentPath) { Remove-Item -Recurse -Force $currentPath }
Invoke-OpenSshScp -ScpArguments ($sshCommon + @("-r", "${sshTarget}:${remoteXui}/", "${backupDir}/current/"))

if (-not (Test-Path $currentPath)) {
  Write-Error "Backup failed: $currentPath was not created"
  exit 1
}

Copy-Item -Path $currentPath -Destination (Join-Path $yearDir "xui.backup.$timestamp") -Recurse
Write-Host "3x-ui backup saved to $yearDir/xui.backup.$timestamp"
Write-Host "Backup completed"
