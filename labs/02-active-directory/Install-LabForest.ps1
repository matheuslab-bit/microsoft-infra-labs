<#
.SYNOPSIS
    Sets up DC01 and promotes it to the first domain controller of a new forest.
.DESCRIPTION
    -Phase Prepare: static IP, DNS pointing to itself and rename to DC01 (restarts the server).
    -Phase Promote: installs AD DS and creates the forest with DNS. The DSRM password is typed at run time.
.EXAMPLE
    .\Install-LabForest.ps1 -Phase Prepare
.EXAMPLE
    .\Install-LabForest.ps1 -Phase Promote -WhatIf
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('Prepare', 'Promote')][string]$Phase,
    [string]$InterfaceAlias = 'Ethernet',
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$dc = $config.VMs | Where-Object { $_.Role -eq 'DomainController' } | Select-Object -First 1

if ($Phase -eq 'Prepare') {
    if ($PSCmdlet.ShouldProcess($InterfaceAlias, "Set static IP $($dc.IPAddress)/$($config.Network.PrefixLength)")) {
        Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $dc.IPAddress `
            -PrefixLength $config.Network.PrefixLength -DefaultGateway $config.Network.Gateway | Out-Null
        # after promotion the DC uses its own DNS
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses '127.0.0.1'
        Write-LabLog -Message "Static IP $($dc.IPAddress) configured."
    }
    if ($env:COMPUTERNAME -ne $dc.Name -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Rename to $($dc.Name) and restart")) {
        Rename-Computer -NewName $dc.Name -Restart
    }
    return
}

if ($PSCmdlet.ShouldProcess($config.Domain.Fqdn, 'Install AD DS and create new forest')) {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null
    $dsrm = Read-Host -Prompt 'DSRM (Directory Services Restore Mode) password' -AsSecureString
    Install-ADDSForest -DomainName $config.Domain.Fqdn -DomainNetbiosName $config.Domain.NetBiosName `
        -ForestMode $config.Domain.ForestMode -DomainMode $config.Domain.ForestMode `
        -InstallDns -SafeModeAdministratorPassword $dsrm -NoRebootOnCompletion:$false -Force
}
