<#
.SYNOPSIS
    Daily DC check: services, replication, disk, certificates and account hygiene, saved as HTML.
.DESCRIPTION
    Each item is OK, WARNING or CRITICAL. Exit code 2 if anything is critical, 1 if there is a warning.
.EXAMPLE
    .\Get-LabADHealthReport.ps1 -ReportPath C:\LabLogs\ad-health.html
#>
#Requires -Modules ActiveDirectory
[CmdletBinding()]
param(
    [string]$ReportPath = (Join-Path -Path $env:TEMP -ChildPath "ad-health_$(Get-Date -Format 'yyyyMMdd').html"),
    [ValidateRange(1, 99)][int]$DiskWarningPercent = 15,
    [ValidateRange(1, 365)][int]$CertificateWarningDays = 30,
    [ValidateRange(30, 365)][int]$StaleDays = 90
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force

function Format-HealthCheck {
    param([string]$Name, [string]$Status, [string]$Detail)
    [pscustomobject]@{ Check = $Name; Status = $Status; Detail = $Detail }
}

$checks = New-Object -TypeName System.Collections.Generic.List[object]

foreach ($service in 'NTDS', 'DNS', 'Netlogon', 'Kdc', 'W32Time', 'DFSR') {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    $status = if ($svc -and $svc.Status -eq 'Running') { 'OK' } else { 'CRITICAL' }
    $checks.Add((Format-HealthCheck -Name "Service $service" -Status $status -Detail $(if ($svc) { [string]$svc.Status } else { 'Not installed' })))
}

$failures = @(Get-ADReplicationFailure -Target $env:COMPUTERNAME -ErrorAction SilentlyContinue | Where-Object { $_.FailureCount -gt 0 })
$checks.Add((Format-HealthCheck -Name 'AD replication' -Status $(if ($failures.Count) { 'CRITICAL' } else { 'OK' }) -Detail "$($failures.Count) partner(s) failing"))

Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' | ForEach-Object {
    $freePercent = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
    $status = if ($freePercent -lt ($DiskWarningPercent / 2)) { 'CRITICAL' } elseif ($freePercent -lt $DiskWarningPercent) { 'WARNING' } else { 'OK' }
    $checks.Add((Format-HealthCheck -Name "Disk $($_.DeviceID)" -Status $status -Detail "$freePercent% free"))
}

$expiring = @(Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.NotAfter -lt (Get-Date).AddDays($CertificateWarningDays) })
$checks.Add((Format-HealthCheck -Name 'Certificates (LocalMachine\My)' -Status $(if ($expiring.Count) { 'WARNING' } else { 'OK' }) `
    -Detail "$($expiring.Count) expiring within $CertificateWarningDays days"))

$locked = @(Search-ADAccount -LockedOut -UsersOnly)
$checks.Add((Format-HealthCheck -Name 'Locked-out users' -Status $(if ($locked.Count -gt 5) { 'WARNING' } else { 'OK' }) -Detail "$($locked.Count) account(s)"))

$neverExpires = @(Get-ADUser -Filter 'PasswordNeverExpires -eq $true -and Enabled -eq $true')
$checks.Add((Format-HealthCheck -Name 'Password never expires (enabled users)' -Status $(if ($neverExpires.Count) { 'WARNING' } else { 'OK' }) -Detail "$($neverExpires.Count) account(s)"))

$stale = @(Search-ADAccount -AccountInactive -TimeSpan ([timespan]::FromDays($StaleDays)) -UsersOnly | Where-Object { $_.Enabled })
$checks.Add((Format-HealthCheck -Name "Inactive users (> $StaleDays days)" -Status $(if ($stale.Count) { 'WARNING' } else { 'OK' }) -Detail "$($stale.Count) account(s)"))

$style = '<style>body{font-family:Segoe UI,Arial;margin:24px}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px 10px}' +
    'th{background:#1F4E79;color:#fff}</style>'
$checks | ConvertTo-Html -Title "AD health - $env:COMPUTERNAME" -Head $style `
    -PreContent "<h2>AD health - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h2>" |
    ForEach-Object { $_ -replace '<td>CRITICAL</td>', '<td style="background:#f8d7da">CRITICAL</td>' -replace '<td>WARNING</td>', '<td style="background:#fff3cd">WARNING</td>' } |
    Set-Content -Path $ReportPath -Encoding UTF8

Write-LabLog -Message "Report written to $ReportPath"
$checks
if ($checks.Status -contains 'CRITICAL') { exit 2 } elseif ($checks.Status -contains 'WARNING') { exit 1 }
