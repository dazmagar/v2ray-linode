# Upload install-caddy.sh and configure Caddy (OpenSSH local-exec; Windows).

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$V2RAY_HOST,
  [string]$PANEL_PORT
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\openssh-helper.ps1")

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $V2RAY_HOST) { $V2RAY_HOST = $env:V2RAY_HOST }
if (-not $PANEL_PORT) { $PANEL_PORT = $env:PANEL_PORT }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $V2RAY_HOST) {
  Write-Error "Required parameters not set"
  exit 1
}

function Escape-BashSq([string]$Value) {
  return $Value.Replace("'", "'\''")
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localScript = Join-Path $scriptDir "install-caddy.sh"
$sshTarget = "$USER@${INSTANCE_IP}"
$sshCommon = Get-SshCommonOptions -PrivateKeyPath $PRIVATE_KEY_PATH

Invoke-OpenSshScp -ScpArguments ($sshCommon + @($localScript, "${sshTarget}:/tmp/install-caddy.sh"))

$vh = Escape-BashSq $V2RAY_HOST
$remote = "chmod +x /tmp/install-caddy.sh && bash /tmp/install-caddy.sh '${vh}' ${PANEL_PORT} 2>&1 | tee /tmp/caddy-install.log || { echo 'Caddy install failed' >&2; exit 1; }"

Invoke-OpenSshRemote -SshArguments ($sshCommon + @($sshTarget, $remote))
