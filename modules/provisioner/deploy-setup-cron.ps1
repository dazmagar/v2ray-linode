# Upload setup-cron-restart.sh and install cron job (OpenSSH local-exec; Windows).

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$CRON_RESTART_SCHEDULE
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\openssh-helper.ps1")

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $CRON_RESTART_SCHEDULE) { $CRON_RESTART_SCHEDULE = $env:CRON_RESTART_SCHEDULE }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $CRON_RESTART_SCHEDULE) {
  Write-Error "Required parameters not set"
  exit 1
}

function Escape-BashSq([string]$Value) {
  return $Value.Replace("'", "'\''")
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localScript = Join-Path $scriptDir "setup-cron-restart.sh"
$remoteScript = "/home/$USER/setup-cron-restart.sh"
$sshTarget = "$USER@${INSTANCE_IP}"
$sshCommon = Get-SshCommonOptions -PrivateKeyPath $PRIVATE_KEY_PATH

Invoke-OpenSshScp -ScpArguments ($sshCommon + @($localScript, "${sshTarget}:${remoteScript}"))

$sched = Escape-BashSq $CRON_RESTART_SCHEDULE
$remote = @"
chmod +x ${remoteScript}
bash ${remoteScript} '${sched}' || { echo 'ERROR: Failed to setup cron job' >&2; exit 1; }
crontab -l | grep -q '3x-ui' && echo 'Cron job verified' || echo 'WARNING: Cron job not found'
"@

Invoke-OpenSshRemote -SshArguments ($sshCommon + @($sshTarget, $remote))
