# Shared OpenSSH helpers for Terraform local-exec on Windows.
# Resolves ssh/scp paths reliably and retries on transient connection errors.

function Get-OpenSshPath {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("ssh", "scp")]
    [string]$Name
  )

  $candidates = @(
    (Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    (Join-Path $env:SystemRoot "System32\OpenSSH\$Name.exe"),
    (Join-Path ${env:ProgramFiles} "Git\usr\bin\$Name.exe")
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  throw "$Name.exe not found. Install OpenSSH Client (Windows optional feature) or Git for Windows."
}

function Get-SshCommonOptions {
  param(
    [Parameter(Mandatory = $true)]
    [string]$PrivateKeyPath
  )

  return @(
    "-i", $PrivateKeyPath,
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=NUL",
    "-o", "ConnectTimeout=20"
  )
}

function Test-SshConnectionReset {
  param([object[]]$Output)

  $text = ($Output | Out-String)
  return $text -match "Connection reset|kex_exchange_identification|Connection closed|banner exchange"
}

function Invoke-OpenSshCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [int]$MaxAttempts = 5,
    [int]$DelaySeconds = 10
  )

  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    $output = & $Executable @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
      if ($output) { $output | Write-Output }
      return
    }

    $output | Write-Output
    if ($attempt -lt $MaxAttempts) {
      $reason = if (Test-SshConnectionReset $output) { "SSH connection reset" } else { "exit code $exitCode" }
      Write-Warning "Attempt $attempt failed ($reason). Retrying in ${DelaySeconds}s..."
      Start-Sleep -Seconds $DelaySeconds
    } else {
      throw "Command failed after $MaxAttempts attempts: $Executable"
    }
  }
}

function Wait-SshHostReady {
  param(
    [Parameter(Mandatory = $true)]
    [string]$User,
    [Parameter(Mandatory = $true)]
    [string]$InstanceIp,
    [Parameter(Mandatory = $true)]
    [string]$PrivateKeyPath,
    [int]$MaxWaitSeconds = 300,
    [int]$PollSeconds = 10
  )

  $sshPath = Get-OpenSshPath -Name "ssh"
  $sshCommon = Get-SshCommonOptions -PrivateKeyPath $PrivateKeyPath
  $target = "$User@${InstanceIp}"
  $deadline = (Get-Date).AddSeconds($MaxWaitSeconds)

  Write-Host "Waiting for SSH on $target (up to ${MaxWaitSeconds}s)..."

  while ((Get-Date) -lt $deadline) {
    $output = & $sshPath @sshCommon $target "echo ready" 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "SSH is ready"
      return
    }
    $output | Write-Output
    Start-Sleep -Seconds $PollSeconds
  }

  throw "SSH not ready on $target after ${MaxWaitSeconds}s"
}

function Invoke-OpenSshScp {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$ScpArguments,
    [int]$MaxAttempts = 5,
    [int]$DelaySeconds = 10
  )

  $scpPath = Get-OpenSshPath -Name "scp"
  Invoke-OpenSshCommand -Executable $scpPath -Arguments $ScpArguments -MaxAttempts $MaxAttempts -DelaySeconds $DelaySeconds
  Start-Sleep -Seconds 3
}

function Invoke-OpenSshRemote {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$SshArguments,
    [int]$MaxAttempts = 5,
    [int]$DelaySeconds = 10
  )

  $sshPath = Get-OpenSshPath -Name "ssh"
  Invoke-OpenSshCommand -Executable $sshPath -Arguments $SshArguments -MaxAttempts $MaxAttempts -DelaySeconds $DelaySeconds
}
