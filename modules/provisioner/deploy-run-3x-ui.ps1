# Upload run-3x-ui.sh and start 3x-ui container (OpenSSH local-exec; Windows).

param(
  [string]$PRIVATE_KEY_PATH,
  [string]$USER,
  [string]$INSTANCE_IP,
  [string]$V2RAY_HOST,
  [string]$PANEL_PORT,
  [string]$PANEL_BASE_PATH,
  [string]$XUI_IMAGE
)

$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\openssh-helper.ps1")

if (-not $PRIVATE_KEY_PATH) { $PRIVATE_KEY_PATH = $env:PRIVATE_KEY_PATH }
if (-not $USER) { $USER = $env:USER }
if (-not $INSTANCE_IP) { $INSTANCE_IP = $env:INSTANCE_IP }
if (-not $V2RAY_HOST) { $V2RAY_HOST = $env:V2RAY_HOST }
if (-not $PANEL_PORT) { $PANEL_PORT = $env:PANEL_PORT }
if (-not $PANEL_BASE_PATH) { $PANEL_BASE_PATH = $env:PANEL_BASE_PATH }
if (-not $XUI_IMAGE) { $XUI_IMAGE = $env:XUI_IMAGE }

if (-not $PRIVATE_KEY_PATH -or -not $USER -or -not $INSTANCE_IP -or -not $XUI_IMAGE) {
  Write-Error "Required parameters not set"
  exit 1
}

function Escape-BashSq([string]$Value) {
  return $Value.Replace("'", "'\''")
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localScript = Join-Path $scriptDir "run-3x-ui.sh"
$remoteScript = "/home/$USER/run-3x-ui.sh"
$sshTarget = "$USER@${INSTANCE_IP}"
$sshCommon = Get-SshCommonOptions -PrivateKeyPath $PRIVATE_KEY_PATH

Invoke-OpenSshScp -ScpArguments ($sshCommon + @($localScript, "${sshTarget}:${remoteScript}"))

$vh = Escape-BashSq $V2RAY_HOST
$pb = Escape-BashSq $PANEL_BASE_PATH
$xi = Escape-BashSq $XUI_IMAGE

$remote = @"
chmod +x ${remoteScript}
bash ${remoteScript} '${vh}' ${PANEL_PORT} '${pb}' '${xi}' 2>&1 | tee /tmp/3x-ui-startup.log || {
  RC=`$?
  echo '=== Container startup failed (exit code: '`$RC') ===' >&2
  cat /tmp/3x-ui-container-deploy.log >&2 2>/dev/null || true
  sudo docker logs 3x-ui >&2 2>&1 || true
  exit `$RC
}
"@

Invoke-OpenSshRemote -SshArguments ($sshCommon + @($sshTarget, $remote))
