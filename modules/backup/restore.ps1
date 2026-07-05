# Restore 3x-ui backup from local backup_path/current to the instance.
# Run before run_3x_ui on a new/fresh instance.

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
  Write-Error "Required parameters not set"
  exit 1
}

$currentPath = Join-Path $BACKUP_PATH "current"
if (-not (Test-Path $currentPath) -or -not (Get-ChildItem $currentPath -ErrorAction SilentlyContinue)) {
  Write-Host "No backup to restore (missing or empty $currentPath); skipping restore"
  exit 0
}

$remoteXui = "/home/$USER/x-ui"
$sshCommon = Get-SshCommonOptions -PrivateKeyPath $PRIVATE_KEY_PATH
$sshTarget = "$USER@${INSTANCE_IP}"

Write-Host "Restoring 3x-ui backup from $currentPath to ${sshTarget}:${remoteXui}"

Invoke-OpenSshRemote -SshArguments ($sshCommon + @($sshTarget, "mkdir -p $remoteXui; sudo chown -R $USER`:$USER $remoteXui"))
Invoke-OpenSshScp -ScpArguments ($sshCommon + @("-r", "$currentPath\*", "${sshTarget}:${remoteXui}/"))

$dbPath = Join-Path $currentPath "db\x-ui.db"
if (Test-Path $dbPath) {
  Invoke-OpenSshRemote -SshArguments ($sshCommon + @($sshTarget, "test -f $remoteXui/db/x-ui.db"))
}

Write-Host "Restore completed"
