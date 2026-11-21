<#
.SYNOPSIS
    Creates users from a CSV file and adds each one to its department group.
.DESCRIPTION
    Logon names follow 'name.surname' without accents (max 20 characters). If the name is taken, a number is added.
    Creates the GG_<Department> groups if needed. The initial password is typed once and must be changed at first logon.
    Saves a CSV report with the accounts created.
.EXAMPLE
    .\Import-LabUsers.ps1 -WhatIf
.EXAMPLE
    .\Import-LabUsers.ps1 -ReportPath C:\LabLogs\users-created.csv
#>
#Requires -Modules ActiveDirectory
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$CsvPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\data\users.csv'),
    [string]$ReportPath = (Join-Path -Path $env:TEMP -ChildPath 'lab-users-created.csv'),
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$domainDn = ConvertTo-LabDistinguishedName -DomainFqdn $config.Domain.Fqdn
$rootDn = "OU=$($config.Domain.RootOuName),$domainDn"
$groupOu = "OU=Seguranca,OU=Grupos,$rootDn"
$users = Import-Csv -Path $CsvPath -Encoding UTF8

foreach ($department in ($users.Department | Sort-Object -Unique)) {
    $groupName = "GG_$department"
    if (-not (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue) -and
        $PSCmdlet.ShouldProcess($groupName, 'Create global security group')) {
        New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Path $groupOu `
            -Description "Usuarios do departamento $department"
        Write-LabLog -Message "Group created: $groupName"
    }
}

$initialPassword = $null
if (-not $WhatIfPreference) {
    $initialPassword = Read-Host -Prompt 'Initial password for new users (must change at logon)' -AsSecureString
}

$report = foreach ($user in $users) {
    $sam = ConvertTo-LabSamAccountName -GivenName $user.GivenName -Surname $user.Surname
    $candidate = $sam
    $suffix = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$candidate'" -ErrorAction SilentlyContinue) {
        $suffix++
        $candidate = '{0}{1}' -f $sam.Substring(0, [Math]::Min($sam.Length, 19)), $suffix
    }
    $ou = "OU=$($user.Department),OU=Usuarios,$rootDn"
    $upn = '{0}@{1}' -f $candidate, $config.Domain.Fqdn

    if ($PSCmdlet.ShouldProcess($upn, "Create user in $ou")) {
        New-ADUser -Name "$($user.GivenName) $($user.Surname)" -GivenName $user.GivenName -Surname $user.Surname `
            -SamAccountName $candidate -UserPrincipalName $upn -DisplayName "$($user.GivenName) $($user.Surname)" `
            -Department $user.Department -Title $user.Title -Path $ou -AccountPassword $initialPassword `
            -ChangePasswordAtLogon $true -Enabled $true
        Add-ADGroupMember -Identity "GG_$($user.Department)" -Members $candidate
        Write-LabLog -Message "User created: $upn"
        [pscustomobject]@{ SamAccountName = $candidate; UserPrincipalName = $upn; Department = $user.Department; CreatedAt = Get-Date -Format s }
    }
}

if ($report) {
    $report | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
    Write-LabLog -Message "Audit report: $ReportPath ($(@($report).Count) accounts)."
}
