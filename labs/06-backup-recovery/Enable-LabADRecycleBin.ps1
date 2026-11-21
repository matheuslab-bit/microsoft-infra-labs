<#
.SYNOPSIS
    Turns on the AD Recycle Bin and can run a delete-and-restore test with a temporary user.
.DESCRIPTION
    With the Recycle Bin on, a deleted user comes back with its groups using Restore-ADObject,
    without restoring a backup. Turning it on cannot be undone.
.EXAMPLE
    .\Enable-LabADRecycleBin.ps1 -RunDrill
#>
#Requires -Modules ActiveDirectory
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$RunDrill,
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$forest = Get-ADForest

$feature = Get-ADOptionalFeature -Filter "Name -eq 'Recycle Bin Feature'"
if (-not $feature.EnabledScopes -and $PSCmdlet.ShouldProcess($forest.Name, 'Enable AD Recycle Bin (irreversible)')) {
    Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $forest.Name -Confirm:$false
    Write-LabLog -Message 'AD Recycle Bin enabled.'
}

if ($RunDrill) {
    $rootDn = 'OU={0},{1}' -f $config.Domain.RootOuName, (ConvertTo-LabDistinguishedName -DomainFqdn $config.Domain.Fqdn)
    $ou = "OU=TI,OU=Usuarios,$rootDn"
    $sam = 'drill.restore'
    if ($PSCmdlet.ShouldProcess($sam, 'Create, delete and restore a test user')) {
        New-ADUser -Name 'Drill Restore' -SamAccountName $sam -Path $ou -Enabled $false
        Add-ADGroupMember -Identity 'GG_TI' -Members $sam
        Remove-ADUser -Identity $sam -Confirm:$false
        $deleted = Get-ADObject -Filter "SamAccountName -eq '$sam'" -IncludeDeletedObjects |
            Where-Object { $_.Deleted } | Select-Object -First 1
        Restore-ADObject -Identity $deleted.ObjectGUID
        $restored = Get-ADUser -Identity $sam -Properties MemberOf
        $kept = [bool]($restored.MemberOf -match 'CN=GG_TI,')
        Write-LabLog -Message "Drill: user restored to $($restored.DistinguishedName); group membership kept: $kept"
        Remove-ADUser -Identity $sam -Confirm:$false
    }
}
