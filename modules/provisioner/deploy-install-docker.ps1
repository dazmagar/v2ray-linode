# Upload startup.sh and ensure Docker is installed (OpenSSH local-exec; Windows).

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\openssh-helper.ps1")

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP) {
  Write-Error "Required parameters not set (PRIVATE_KEY_PATH, USER, INSTANCE_IP)"
  exit 1
}

Wait-SshHostReady -User $USER -InstanceIp $INSTANCE_IP -PrivateKeyPath $PRIVATE_KEY_PATH

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localStartup = Join-Path $scriptDir "startup.sh"
$sshTarget = "$USER@${INSTANCE_IP}"
$sshCommon = Get-SshCommonOptions -PrivateKeyPath $PRIVATE_KEY_PATH

Invoke-OpenSshScp -ScpArguments ($sshCommon + @($localStartup, "${sshTarget}:/tmp/startup.sh"))

$remoteUser = $USER.Replace("'", "'\''")
$remote = @"
if sudo docker --version &> /dev/null && sudo systemctl is-active --quiet docker; then
  echo 'Docker already installed and running'
else
  chmod +x /tmp/startup.sh
  bash /tmp/startup.sh '${remoteUser}'
  if ! sudo docker --version &> /dev/null; then
    if [ ! -f /usr/bin/docker ]; then
      echo 'Error: Docker installation failed'
      exit 1
    fi
  fi
  echo 'Docker installed successfully'
fi
"@

Invoke-OpenSshRemote -SshArguments ($sshCommon + @($sshTarget, $remote))
