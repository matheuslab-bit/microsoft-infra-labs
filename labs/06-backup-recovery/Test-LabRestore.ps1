<#
.SYNOPSIS
    Proves the latest file backup is restorable: restores a random sample to a scratch folder and compares SHA256 hashes with the manifest.
.DESCRIPTION
    A backup that was never restored is only an assumption. This script picks the newest snapshot, restores
    SampleSize random files (or all of them) to a temporary folder, verifies each hash against _manifest.csv
    and outputs a pass/fail report. Exit code 1 when any file fails, so it can feed monitoring or a scheduled task.
.EXAMPLE
    .\Test-LabRestore.ps1 -SampleSize 20 -ReportPath E:\Backups\logs\restore-test.csv
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 100000)][int]$SampleSize = 20,
    [string]$ReportPath,
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$backup = (Get-LabConfig -Path $ConfigPath).Backup
$latest = Get-ChildItem -Path (Join-Path -Path $backup.TargetPath -ChildPath 'files') -Directory |
    Sort-Object -Property Name -Descending | Select-Object -First 1
if (-not $latest) { throw "No snapshot found under $($backup.TargetPath)\files." }

$scratch = Join-Path -Path $env:TEMP -ChildPath "restore-test_$(Get-Date -Format 'yyyyMMddHHmmss')"
$results = foreach ($set in Get-ChildItem -Path $latest.FullName -Directory) {
    $manifestPath = Join-Path -Path $set.FullName -ChildPath '_manifest.csv'
    if (-not (Test-Path -Path $manifestPath)) { continue }
    $sample = Import-Csv -Path $manifestPath -Encoding UTF8 | Get-Random -Count $SampleSize
    foreach ($entry in $sample) {
        $source = Join-Path -Path $set.FullName -ChildPath $entry.RelativePath
        $restored = Join-Path -Path $scratch -ChildPath (Join-Path -Path $set.Name -ChildPath $entry.RelativePath)
        New-Item -Path (Split-Path -Path $restored -Parent) -ItemType Directory -Force | Out-Null
        Copy-Item -Path $source -Destination $restored -Force
        $hash = (Get-FileHash -Path $restored -Algorithm SHA256).Hash
        [pscustomobject]@{
            Snapshot = $latest.Name
            File     = Join-Path -Path $set.Name -ChildPath $entry.RelativePath
            Expected = $entry.SHA256
            Actual   = $hash
            Result   = if ($hash -eq $entry.SHA256) { 'PASS' } else { 'FAIL' }
        }
    }
}
Remove-Item -Path $scratch -Recurse -Force -ErrorAction SilentlyContinue

$failed = @($results | Where-Object { $_.Result -eq 'FAIL' })
if ($ReportPath) { $results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8 }
Write-LabLog -Level ($(if ($failed.Count) { 'Error' } else { 'Info' })) `
    -Message "Restore test on snapshot $($latest.Name): $(@($results).Count) files checked, $($failed.Count) failed."
$results
if ($failed.Count) { exit 1 }
