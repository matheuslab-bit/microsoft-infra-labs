<#
.SYNOPSIS
    Backs up all GPOs to a dated folder, saves an HTML report of each one and deletes old backups.
.DESCRIPTION
    Meant to run as a scheduled task on the DC. Use Restore-GPO to bring a GPO back from a backup folder.
.EXAMPLE
    .\Backup-LabGpo.ps1 -BackupRoot E:\Backups\GPO -RetentionDays 30
#>
#Requires -Modules GroupPolicy
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$BackupRoot = 'E:\Backups\GPO',
    [ValidateRange(1, 365)][int]$RetentionDays = 30
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$target = Join-Path -Path $BackupRoot -ChildPath (Get-Date -Format 'yyyy-MM-dd_HHmm')

if ($PSCmdlet.ShouldProcess($target, 'Back up all GPOs and export HTML reports')) {
    $reports = Join-Path -Path $target -ChildPath 'reports'
    New-Item -Path $reports -ItemType Directory -Force | Out-Null
    $backups = Backup-GPO -All -Path $target -Comment "Scheduled backup $(Get-Date -Format s)"
    foreach ($gpo in Get-GPO -All) {
        $safeName = $gpo.DisplayName -replace '[\\/:*?"<>|]', '_'
        Get-GPOReport -Guid $gpo.Id -ReportType Html -Path (Join-Path -Path $reports -ChildPath "$safeName.html")
    }
    Write-LabLog -Message "$(@($backups).Count) GPOs backed up to $target."
}

Get-ChildItem -Path $BackupRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$RetentionDays) } |
    ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.FullName, "Remove backup older than $RetentionDays days")) {
            Remove-Item -Path $_.FullName -Recurse -Force
            Write-LabLog -Message "Old backup removed: $($_.FullName)"
        }
    }
