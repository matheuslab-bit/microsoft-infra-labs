<#
.SYNOPSIS
    Applies the domain password policy, a stricter policy for IT and the workstation security GPO.
.DESCRIPTION
    Domain: 12+ characters, 24 history, lockout after 5 tries for 15 minutes.
    GG_TI (fine-grained policy): 15+ characters, lockout after 3 tries.
    GPO 'LAB - Estacoes - Baseline' on OU Estacoes: firewall on, SMBv1 off, USB storage read-only,
    screen lock after 15 minutes, last user name hidden at logon.
.EXAMPLE
    .\New-LabBaselineGpo.ps1 -WhatIf
#>
#Requires -Modules ActiveDirectory, GroupPolicy
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$domain = $config.Domain.Fqdn
$rootDn = 'OU={0},{1}' -f $config.Domain.RootOuName, (ConvertTo-LabDistinguishedName -DomainFqdn $domain)
$workstationOu = "OU=Estacoes,OU=Computadores,$rootDn"

if ($PSCmdlet.ShouldProcess($domain, 'Set default domain password and lockout policy')) {
    Set-ADDefaultDomainPasswordPolicy -Identity $domain -MinPasswordLength 12 -PasswordHistoryCount 24 `
        -ComplexityEnabled $true -MaxPasswordAge 90.00:00:00 -MinPasswordAge 1.00:00:00 `
        -LockoutThreshold 5 -LockoutDuration 00:15:00 -LockoutObservationWindow 00:15:00
    Write-LabLog -Message 'Default domain password policy applied.'
}

$psoName = 'PSO-TI-Administradores'
if (-not (Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$psoName'" -ErrorAction SilentlyContinue) -and
    $PSCmdlet.ShouldProcess($psoName, 'Create fine-grained password policy for GG_TI')) {
    New-ADFineGrainedPasswordPolicy -Name $psoName -Precedence 10 -MinPasswordLength 15 -PasswordHistoryCount 24 `
        -ComplexityEnabled $true -ReversibleEncryptionEnabled $false -MaxPasswordAge 60.00:00:00 `
        -MinPasswordAge 1.00:00:00 -LockoutThreshold 3 -LockoutDuration 00:30:00 -LockoutObservationWindow 00:30:00
    Add-ADFineGrainedPasswordPolicySubject -Identity $psoName -Subjects 'GG_TI'
    Write-LabLog -Message "PSO '$psoName' applied to GG_TI."
}

$gpoName = 'LAB - Estacoes - Baseline'
$gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
if (-not $gpo -and $PSCmdlet.ShouldProcess($gpoName, 'Create GPO')) {
    $gpo = New-GPO -Name $gpoName -Comment 'Security baseline for domain workstations (managed by microsoft-infra-labs).'
}

$settings = @(
    @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile';   ValueName = 'EnableFirewall'; Type = 'DWord'; Value = 1 }
    @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\PrivateProfile';  ValueName = 'EnableFirewall'; Type = 'DWord'; Value = 1 }
    @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile';   ValueName = 'EnableFirewall'; Type = 'DWord'; Value = 1 }
    @{ Key = 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters';  ValueName = 'SMB1';           Type = 'DWord'; Value = 0 }
    @{ Key = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}'; ValueName = 'Deny_Write'; Type = 'DWord'; Value = 1 }
    @{ Key = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System';  ValueName = 'DontDisplayLastUserName'; Type = 'DWord'; Value = 1 }
    @{ Key = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System';  ValueName = 'InactivityTimeoutSecs';   Type = 'DWord'; Value = 900 }
    @{ Key = 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop';  ValueName = 'ScreenSaveActive';    Type = 'String'; Value = '1' }
    @{ Key = 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop';  ValueName = 'ScreenSaverIsSecure'; Type = 'String'; Value = '1' }
    @{ Key = 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop';  ValueName = 'ScreenSaveTimeOut';   Type = 'String'; Value = '900' }
)

if ($gpo) {
    foreach ($setting in $settings) {
        if ($PSCmdlet.ShouldProcess("$gpoName :: $($setting.Key)\$($setting.ValueName)", "Set $($setting.Value)")) {
            Set-GPRegistryValue -Name $gpoName -Key $setting.Key -ValueName $setting.ValueName -Type $setting.Type -Value $setting.Value | Out-Null
        }
    }
    $linked = (Get-GPInheritance -Target $workstationOu).GpoLinks | Where-Object { $_.DisplayName -eq $gpoName }
    if (-not $linked -and $PSCmdlet.ShouldProcess($workstationOu, "Link GPO '$gpoName'")) {
        New-GPLink -Name $gpoName -Target $workstationOu -LinkEnabled Yes | Out-Null
        Write-LabLog -Message "GPO '$gpoName' linked to $workstationOu."
    }
}
