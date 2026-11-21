<#
.SYNOPSIS
    Standardized employee offboarding: disables the account, resets the password, removes group memberships, moves it to OU Desativados and keeps an audit trail.
.DESCRIPTION
    Replaces a manual checklist that is easy to get wrong. Before removing anything, the current group
    memberships are exported to CSV so access can be restored or audited later. The ticket number is
    written to the account description.
.EXAMPLE
    .\Invoke-LabUserOffboarding.ps1 -SamAccountName diego.araujo -Ticket CHG-1042 -WhatIf
#>
#Requires -Modules ActiveDirectory
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'Throwaway random password generated in memory; it is never stored, logged or displayed.')]
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string[]]$SamAccountName,
    [Parameter(Mandatory)][ValidatePattern('^[A-Z]{2,5}-\d+$')][string]$Ticket,
    [string]$AuditPath = (Join-Path -Path $env:TEMP -ChildPath 'offboarding'),
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$disabledOu = 'OU=Desativados,OU={0},{1}' -f $config.Domain.RootOuName, (ConvertTo-LabDistinguishedName -DomainFqdn $config.Domain.Fqdn)
New-Item -Path $AuditPath -ItemType Directory -Force | Out-Null
$logPath = Join-Path -Path $AuditPath -ChildPath 'offboarding.log'

foreach ($sam in $SamAccountName) {
    $user = Get-ADUser -Identity $sam -Properties MemberOf, Description
    if (-not $PSCmdlet.ShouldProcess($user.UserPrincipalName, "Offboard ($Ticket)")) { continue }

    $groups = $user.MemberOf | ForEach-Object { Get-ADGroup -Identity $_ }
    $groups | Select-Object -Property @{ n = 'User'; e = { $sam } }, Name, DistinguishedName |
        Export-Csv -Path (Join-Path -Path $AuditPath -ChildPath "$sam`_$Ticket`_groups.csv") -NoTypeInformation -Encoding UTF8

    Disable-ADAccount -Identity $user
    # Random 32-character password that nobody knows, so cached credentials stop working too.
    $bytes = New-Object -TypeName byte[] -ArgumentList 24
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $random = ConvertTo-SecureString -String ([Convert]::ToBase64String($bytes)) -AsPlainText -Force
    Set-ADAccountPassword -Identity $user -Reset -NewPassword $random

    foreach ($group in $groups) {
        Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
    }
    Set-ADUser -Identity $user -Description ("Desligado em {0} - {1} - antes: {2}" -f (Get-Date -Format 'yyyy-MM-dd'), $Ticket, $user.Description)
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOu

    Write-LabLog -LogPath $logPath -Message "$sam offboarded ($Ticket): disabled, password reset, $(@($groups).Count) group(s) removed, moved to Desativados."
}
