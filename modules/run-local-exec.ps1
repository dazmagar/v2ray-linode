# Runs the platform-appropriate local-exec script for Terraform provisioners.
param(
  [Parameter(Mandatory = $true)]
  [string]$ShScript,
  [Parameter(Mandatory = $true)]
  [string]$PsScript
)

$ErrorActionPreference = "Stop"

if ($env:OS -match "Windows" -or ($PSVersionTable.PSPlatform -eq "Win")) {
  if (-not (Test-Path -LiteralPath $PsScript)) {
    throw "PowerShell script not found: $PsScript"
  }
  & $PsScript
  exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $ShScript)) {
  throw "Shell script not found: $ShScript"
}

& /bin/sh $ShScript
exit $LASTEXITCODE
