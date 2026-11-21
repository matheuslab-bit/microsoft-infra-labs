<#
.SYNOPSIS
    Installs and authorizes DHCP on the DC and creates the workstation scope.
.DESCRIPTION
    Before changing anything, checks that the scope is inside the lab subnet and does not include
    any server's static IP. Stops with an error if it does.
.EXAMPLE
    .\Set-LabDhcp.ps1 -WhatIf
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$dhcp = $config.Dhcp
$subnet = Get-LabIPv4Network -Address $config.Network.Prefix -PrefixLength $config.Network.PrefixLength

foreach ($address in $dhcp.StartRange, $dhcp.EndRange) {
    if (-not (Test-LabAddressInRange -Address $address -StartAddress $subnet.FirstHost -EndAddress $subnet.LastHost)) {
        throw "DHCP range address $address is outside $($subnet.Network)/$($subnet.PrefixLength)."
    }
}
foreach ($vm in ($config.VMs | Where-Object { Test-LabIPv4Address -Address $_.IPAddress })) {
    if (Test-LabAddressInRange -Address $vm.IPAddress -StartAddress $dhcp.StartRange -EndAddress $dhcp.EndRange) {
        throw "Static address of $($vm.Name) ($($vm.IPAddress)) overlaps the DHCP range."
    }
}

$dc = $config.VMs | Where-Object { $_.Role -eq 'DomainController' } | Select-Object -First 1
$dcFqdn = '{0}.{1}' -f $dc.Name, $config.Domain.Fqdn

if ($PSCmdlet.ShouldProcess($dcFqdn, 'Install DHCP role and authorize in Active Directory')) {
    Install-WindowsFeature -Name DHCP -IncludeManagementTools | Out-Null
    if (-not (Get-DhcpServerInDC | Where-Object { $_.DnsName -eq $dcFqdn })) {
        Add-DhcpServerInDC -DnsName $dcFqdn -IPAddress $dc.IPAddress
    }
    # removes the 'configuration required' warning in Server Manager
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' -Name ConfigurationState -Value 2
    Write-LabLog -Message "DHCP authorized on $dcFqdn."
}

if (-not (Get-DhcpServerv4Scope -ScopeId $subnet.Network -ErrorAction SilentlyContinue) -and
    $PSCmdlet.ShouldProcess($dhcp.ScopeName, "Create scope $($dhcp.StartRange)-$($dhcp.EndRange)")) {
    Add-DhcpServerv4Scope -Name $dhcp.ScopeName -StartRange $dhcp.StartRange -EndRange $dhcp.EndRange `
        -SubnetMask $subnet.SubnetMask -LeaseDuration ([timespan]$dhcp.LeaseDuration) -State Active
    Set-DhcpServerv4OptionValue -ScopeId $subnet.Network -Router $dhcp.Router -DnsServer $dhcp.DnsServers `
        -DnsDomain $config.Domain.Fqdn
    # DHCP registers the client in DNS and removes the record when the lease expires
    Set-DhcpServerv4DnsSetting -ScopeId $subnet.Network -DynamicUpdates Always -DeleteDnsRRonLeaseExpiry $true
    Write-LabLog -Message "Scope '$($dhcp.ScopeName)' created and activated."
}
