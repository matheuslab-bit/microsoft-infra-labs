<#
.SYNOPSIS
    Runs the lab backup routine: versioned file backup of the shares with Robocopy and, on a DC, a system state backup.
.DESCRIPTION
    - Files: each run mirrors the configured sources into <Target>\files\yyyy-MM-dd_HHmm, preserving NTFS ACLs
      (/COPYALL), and writes a SHA256 manifest used later by Test-LabRestore.ps1.
    - System state (-IncludeSystemState): wbadmin system state backup, which contains the AD database (NTDS),
      SYSVOL and the registry. Requires the Windows-Server-Backup feature and a dedicated volume.
    - Retention: snapshot folders older than RetentionDays are removed.
    Robocopy exit codes 0-7 mean success; 8 or higher is a failure and stops the script.
.EXAMPLE
    .\Invoke-LabBackup.ps1 -WhatIf
.EXAMPLE
    .\Invoke-LabBackup.ps1 -IncludeSystemState -SystemStateTarget 'E:'
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$IncludeSystemState,
    [string]$SystemStateTarget = 'E:',
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$backup = (Get-LabConfig -Path $ConfigPath).Backup
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$snapshot = Join-Path -Path $backup.TargetPath -ChildPath "files\$stamp"
$logPath = Join-Path -Path $backup.TargetPath -ChildPath "logs\backup_$stamp.log"

foreach ($source in $backup.Sources) {
    $destination = Join-Path -Path $snapshot -ChildPath (Split-Path -Path $source -Leaf)
    if ($PSCmdlet.ShouldProcess("$source -> $destination", 'Robocopy with ACLs')) {
        New-Item -Path $destination -ItemType Directory -Force | Out-Null
        & robocopy.exe $source $destination /E /COPYALL /DCOPY:DAT /R:2 /W:5 /NP /NFL /NDL "/LOG+:$logPath" | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "Robocopy failed for $source (exit code $LASTEXITCODE). See $logPath" }

        $manifest = Get-ChildItem -Path $destination -Recurse -File | Where-Object { $_.Name -ne '_manifest.csv' } | ForEach-Object {
            [pscustomobject]@{
                RelativePath = $_.FullName.Substring($destination.Length).TrimStart('\')
                SHA256       = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
                Length       = $_.Length
            }
        }
        $manifest | Export-Csv -Path (Join-Path -Path $destination -ChildPath '_manifest.csv') -NoTypeInformation -Encoding UTF8
        Write-LabLog -LogPath $logPath -Message "$source backed up: $(@($manifest).Count) files."
    }
}

if ($IncludeSystemState -and $PSCmdlet.ShouldProcess($SystemStateTarget, 'wbadmin system state backup')) {
    if (-not (Get-WindowsFeature -Name Windows-Server-Backup).Installed) {
        Install-WindowsFeature -Name Windows-Server-Backup | Out-Null
    }
    & wbadmin.exe start systemstatebackup "-backupTarget:$SystemStateTarget" -quiet
    if ($LASTEXITCODE -ne 0) { throw "System state backup failed (exit code $LASTEXITCODE)." }
    Write-LabLog -LogPath $logPath -Message "System state backup completed on $SystemStateTarget."
}

Get-ChildItem -Path (Join-Path -Path $backup.TargetPath -ChildPath 'files') -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$backup.RetentionDays) } |
    ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.FullName, "Remove snapshot older than $($backup.RetentionDays) days")) {
            Remove-Item -Path $_.FullName -Recurse -Force
            Write-LabLog -LogPath $logPath -Message "Expired snapshot removed: $($_.Name)"
        }
    }
