<#
.SYNOPSIS
    Lists users and computers with no logon for N days. With -Disable, disables them and moves them to Desativados.
.DESCRIPTION
    Uses lastLogonTimestamp (accurate to about 14 days). New accounts that never logged on are skipped
    during a grace period. Review the list before using -Disable.
.EXAMPLE
    .\Get-LabStaleAccount.ps1 -DaysInactive 90 | Export-Csv stale.csv -NoTypeInformation
.EXAMPLE
    .\Get-LabStaleAccount.ps1 -DaysInactive 90 -Disable -WhatIf
#>
#Requires -Modules ActiveDirectory
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateRange(30, 730)][int]$DaysInactive = 90,
    [ValidateRange(0, 90)][int]$GraceDays = 14,
    [switch]$Disable,
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$disabledOu = 'OU=Desativados,OU={0},{1}' -f $config.Domain.RootOuName, (ConvertTo-LabDistinguishedName -DomainFqdn $config.Domain.Fqdn)
$cutoff = (Get-Date).AddDays(-$DaysInactive)
$graceCutoff = (Get-Date).AddDays(-$GraceDays)

$users = Get-ADUser -Filter 'Enabled -eq $true' -Properties LastLogonTimestamp, WhenCreated |
    Select-Object -Property Name, SamAccountName, DistinguishedName, WhenCreated, @{ n = 'Type'; e = { 'User' } },
        @{ n = 'LastLogon'; e = { if ($_.LastLogonTimestamp) { [DateTime]::FromFileTime($_.LastLogonTimestamp) } } }
$computers = Get-ADComputer -Filter 'Enabled -eq $true' -Properties LastLogonTimestamp, WhenCreated |
    Select-Object -Property Name, SamAccountName, DistinguishedName, WhenCreated, @{ n = 'Type'; e = { 'Computer' } },
        @{ n = 'LastLogon'; e = { if ($_.LastLogonTimestamp) { [DateTime]::FromFileTime($_.LastLogonTimestamp) } } }

$stale = @($users) + @($computers) | Where-Object {
    $_.WhenCreated -lt $graceCutoff -and ($null -eq $_.LastLogon -or $_.LastLogon -lt $cutoff)
} | Where-Object { $_.SamAccountName -notin 'krbtgt', 'Administrator', 'Guest' }

foreach ($account in $stale) {
    if ($Disable -and $PSCmdlet.ShouldProcess($account.DistinguishedName, 'Disable and move to Desativados')) {
        Disable-ADAccount -Identity $account.DistinguishedName
        Move-ADObject -Identity $account.DistinguishedName -TargetPath $disabledOu
        Write-LabLog -Message "Disabled stale $($account.Type): $($account.SamAccountName)"
    }
    $account
}
