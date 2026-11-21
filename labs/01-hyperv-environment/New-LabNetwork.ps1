<#
.SYNOPSIS
    Creates the lab network: internal Hyper-V switch, gateway IP on the host and NAT.
.DESCRIPTION
    Values come from config/lab.psd1. Safe to run again: anything that already exists is skipped.
    VMs get internet through the host NAT and stay off the home network.
.EXAMPLE
    .\New-LabNetwork.ps1 -WhatIf
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$net = (Get-LabConfig -Path $ConfigPath).Network

if (-not (Get-VMSwitch -Name $net.SwitchName -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($net.SwitchName, 'Create Internal Hyper-V switch')) {
        New-VMSwitch -Name $net.SwitchName -SwitchType Internal | Out-Null
        Write-LabLog -Message "Switch '$($net.SwitchName)' created."
    }
} else {
    Write-LabLog -Message "Switch '$($net.SwitchName)' already exists."
}

$adapter = Get-NetAdapter -Name "vEthernet ($($net.SwitchName))" -ErrorAction SilentlyContinue
if ($adapter -and -not (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $net.Gateway -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($adapter.Name, "Assign gateway $($net.Gateway)/$($net.PrefixLength)")) {
        New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $net.Gateway -PrefixLength $net.PrefixLength | Out-Null
        Write-LabLog -Message "Gateway $($net.Gateway) assigned to $($adapter.Name)."
    }
}

$natPrefix = '{0}/{1}' -f $net.Prefix, $net.PrefixLength
if (-not (Get-NetNat -Name $net.NatName -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($natPrefix, "Create NAT '$($net.NatName)'")) {
        New-NetNat -Name $net.NatName -InternalIPInterfaceAddressPrefix $natPrefix | Out-Null
        Write-LabLog -Message "NAT '$($net.NatName)' created for $natPrefix."
    }
} else {
    Write-LabLog -Message "NAT '$($net.NatName)' already exists."
}
