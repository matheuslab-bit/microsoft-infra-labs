<#
.SYNOPSIS
    Checks the Lab 01 environment and writes an evidence report: switch, NAT, VMs, guest internet and checkpoint rollback.
.DESCRIPTION
    Host checks (always): internal switch, gateway IP on the host, NAT, and for each VM in config/lab.psd1:
    generation 2, Secure Boot, and a virtual TPM on Windows VMs. VMs that were not created yet are reported as SKIP.

    Guest checks (with -Credential and the VM running): uses PowerShell Direct to read the guest IP
    and to test outbound HTTPS to the internet through the host NAT.

    Checkpoint test (with -IncludeCheckpointTest): takes a checkpoint, creates a marker file in the guest,
    restores the checkpoint and confirms the file is gone. The checkpoint is removed at the end.

    Every check returns PASS, FAIL or SKIP. The report is saved as text so it can be attached as evidence.
    Exits with code 1 if any check fails.
.EXAMPLE
    .\Test-LabEnvironment.ps1
.EXAMPLE
    .\Test-LabEnvironment.ps1 -VMName DC01 -Credential (Get-Credential Administrator) -IncludeCheckpointTest
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$VMName = 'DC01',
    [pscredential]$Credential,
    [switch]$IncludeCheckpointTest,
    [string]$ReportPath,
    [ValidateRange(30, 1800)][int]$BootTimeoutSeconds = 300,
    [string]$InternetProbe = '1.1.1.1',
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$net = $config.Network
if (-not $ReportPath) { $ReportPath = Join-Path -Path $config.Lab.VMPath -ChildPath 'evidencia-lab01.txt' }

$results = New-Object -TypeName System.Collections.Generic.List[object]
function Add-Result([string]$Check, [string]$Result, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = $Result; Detail = $Detail })
}
function Test-GuestReady([string]$Name, [pscredential]$Cred) {
    try { Invoke-Command -VMName $Name -Credential $Cred -ScriptBlock { $true } -ErrorAction Stop } catch { $false }
}
function Wait-GuestReady([string]$Name, [pscredential]$Cred, [int]$TimeoutSeconds) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-GuestReady -Name $Name -Cred $Cred) { return $true }
        Start-Sleep -Seconds 10
    }
    $false
}

# --- Host: switch, gateway and NAT -----------------------------------------------------------
$switch = Get-VMSwitch -Name $net.SwitchName -ErrorAction SilentlyContinue
if ($switch -and $switch.SwitchType -eq 'Internal') {
    Add-Result -Check 'Switch' -Result 'PASS' -Detail "$($net.SwitchName) is Internal"
} else {
    Add-Result -Check 'Switch' -Result 'FAIL' -Detail "$($net.SwitchName) missing or not Internal"
}

$gateway = Get-NetIPAddress -IPAddress $net.Gateway -ErrorAction SilentlyContinue
if ($gateway -and $gateway.PrefixLength -eq $net.PrefixLength) {
    Add-Result -Check 'Gateway on host' -Result 'PASS' -Detail "$($net.Gateway)/$($net.PrefixLength) on $($gateway.InterfaceAlias)"
} else {
    Add-Result -Check 'Gateway on host' -Result 'FAIL' -Detail "$($net.Gateway)/$($net.PrefixLength) not found"
}

$natPrefix = '{0}/{1}' -f $net.Prefix, $net.PrefixLength
$nat = Get-NetNat -Name $net.NatName -ErrorAction SilentlyContinue
$otherNat = @(Get-NetNat -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne $net.NatName })
if ($nat -and $nat.InternalIPInterfaceAddressPrefix -eq $natPrefix) {
    $note = if ($otherNat.Count) { "; other NATs present: $($otherNat.Name -join ', ')" } else { '; no other NAT' }
    Add-Result -Check 'NAT' -Result 'PASS' -Detail "$($net.NatName) for $natPrefix$note"
} else {
    Add-Result -Check 'NAT' -Result 'FAIL' -Detail "$($net.NatName) for $natPrefix not found"
}

# --- Host: VM settings -----------------------------------------------------------------------
foreach ($vmDef in $config.VMs) {
    $vm = Get-VM -Name $vmDef.Name -ErrorAction SilentlyContinue
    if (-not $vm) { Add-Result -Check "VM $($vmDef.Name)" -Result 'SKIP' -Detail 'not created yet'; continue }
    $problems = @()
    if ($vm.Generation -ne 2) { $problems += 'not generation 2' }
    if ((Get-VMFirmware -VMName $vm.Name).SecureBoot -ne 'On') { $problems += 'Secure Boot off' }
    if ($vmDef.Role -ne 'Monitoring' -and -not (Get-VMSecurity -VMName $vm.Name).TpmEnabled) { $problems += 'no vTPM' }
    $adapter = Get-VMNetworkAdapter -VMName $vm.Name | Select-Object -First 1
    if ($adapter.SwitchName -ne $net.SwitchName) { $problems += "connected to '$($adapter.SwitchName)'" }
    if ($problems) {
        Add-Result -Check "VM $($vmDef.Name)" -Result 'FAIL' -Detail ($problems -join ', ')
    } else {
        Add-Result -Check "VM $($vmDef.Name)" -Result 'PASS' -Detail "Gen2, Secure Boot, $($vm.ProcessorCount) vCPU, state $($vm.State)"
    }
}

# --- Guest: IP and internet through the NAT ---------------------------------------------------
$target = Get-VM -Name $VMName -ErrorAction SilentlyContinue
if (-not $Credential) {
    Add-Result -Check "Guest $VMName internet" -Result 'SKIP' -Detail 'run with -Credential to test inside the VM'
} elseif (-not $target -or $target.State -ne 'Running') {
    Add-Result -Check "Guest $VMName internet" -Result 'SKIP' -Detail 'VM is not running'
} elseif (-not (Test-GuestReady -Name $VMName -Cred $Credential)) {
    Add-Result -Check "Guest $VMName internet" -Result 'FAIL' -Detail 'PowerShell Direct did not answer (OS installed? right password?)'
} else {
    $guest = Invoke-Command -VMName $VMName -Credential $Credential -ArgumentList $InternetProbe -ScriptBlock {
        param($Probe)
        $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1
        $https = Test-NetConnection -ComputerName $Probe -Port 443 -WarningAction SilentlyContinue
        [pscustomobject]@{ Name = $env:COMPUTERNAME; IP = $ip.IPAddress; Https = $https.TcpTestSucceeded }
    }
    if (-not $guest.IP) {
        Add-Result -Check "Guest $VMName internet" -Result 'FAIL' -Detail 'no IPv4 address (set the static IP first: Lab 02, -Phase Prepare)'
    } elseif ($guest.Https) {
        Add-Result -Check "Guest $VMName internet" -Result 'PASS' -Detail "$($guest.Name) $($guest.IP) reached ${InternetProbe}:443 through the NAT"
    } else {
        Add-Result -Check "Guest $VMName internet" -Result 'FAIL' -Detail "$($guest.Name) $($guest.IP) could not reach ${InternetProbe}:443"
    }
}

# --- Checkpoint: take, change, restore, confirm -------------------------------------------------
if ($IncludeCheckpointTest) {
    $checkpointName = 'lab01-checkpoint-test'
    $marker = 'C:\lab01-checkpoint-marker.txt'
    if (-not $Credential -or -not $target -or $target.State -ne 'Running') {
        Add-Result -Check 'Checkpoint rollback' -Result 'SKIP' -Detail "needs -Credential and $VMName running"
    } elseif ($PSCmdlet.ShouldProcess($VMName, "Checkpoint, change and restore ($checkpointName)")) {
        Checkpoint-VM -Name $VMName -SnapshotName $checkpointName
        Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {
            param($Path) Set-Content -Path $Path -Value "created $(Get-Date -Format s)"
        } -ArgumentList $marker
        Restore-VMCheckpoint -VMName $VMName -Name $checkpointName -Confirm:$false
        if ((Get-VM -Name $VMName).State -ne 'Running') { Start-VM -Name $VMName }
        if (Wait-GuestReady -Name $VMName -Cred $Credential -TimeoutSeconds $BootTimeoutSeconds) {
            $stillThere = Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {
                param($Path) Test-Path -Path $Path
            } -ArgumentList $marker
            if ($stillThere) {
                Add-Result -Check 'Checkpoint rollback' -Result 'FAIL' -Detail 'marker file still exists after the restore'
            } else {
                Add-Result -Check 'Checkpoint rollback' -Result 'PASS' -Detail 'file created after the checkpoint was gone after the restore'
            }
        } else {
            Add-Result -Check 'Checkpoint rollback' -Result 'FAIL' -Detail "VM did not answer within $BootTimeoutSeconds s after the restore"
        }
        Remove-VMCheckpoint -VMName $VMName -Name $checkpointName -ErrorAction SilentlyContinue
    }
}

# --- Report --------------------------------------------------------------------------------------
$header = "Lab 01 - environment check | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | host $env:COMPUTERNAME"
$table = $results | Format-Table -Property Check, Result, Detail -AutoSize -Wrap | Out-String -Width 200
$reportDir = Split-Path -Path $ReportPath -Parent
if ($reportDir -and -not (Test-Path -Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }
Set-Content -Path $ReportPath -Value ($header, $table) -Encoding UTF8
Write-LabLog -Message "Report saved to $ReportPath"

$results
if ($results.Result -contains 'FAIL') { exit 1 }
