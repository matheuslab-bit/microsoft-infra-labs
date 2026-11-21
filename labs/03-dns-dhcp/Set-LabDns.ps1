<#
.SYNOPSIS
    Configures DNS on the DC: forwarders, reverse zone, scavenging and records for the servers.
.EXAMPLE
    .\Set-LabDns.ps1 -WhatIf
#>
#Requires -Modules DnsServer
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$zone = $config.Domain.Fqdn
$networkId = '{0}/{1}' -f $config.Network.Prefix, $config.Network.PrefixLength

if ($PSCmdlet.ShouldProcess('DNS Server', "Set forwarders $($config.Domain.DnsForwarders -join ', ')")) {
    Set-DnsServerForwarder -IPAddress $config.Domain.DnsForwarders -PassThru | Out-Null
    Write-LabLog -Message 'Forwarders configured.'
}

$octets = $config.Network.Prefix.Split('.')
$reverseZone = '{0}.{1}.{2}.in-addr.arpa' -f $octets[2], $octets[1], $octets[0]
if (-not (Get-DnsServerZone -Name $reverseZone -ErrorAction SilentlyContinue) -and
    $PSCmdlet.ShouldProcess($reverseZone, 'Create AD-integrated reverse lookup zone')) {
    Add-DnsServerPrimaryZone -NetworkId $networkId -ReplicationScope Forest -DynamicUpdate Secure
    Write-LabLog -Message "Reverse zone created: $reverseZone"
}

# clean up old records left by DHCP clients (7 days no-refresh + 7 days refresh)
if ($PSCmdlet.ShouldProcess('DNS Server', 'Enable aging and scavenging (7d/7d)')) {
    Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7.00:00:00 -ApplyOnAllZones `
        -NoRefreshInterval 7.00:00:00 -RefreshInterval 7.00:00:00
}

foreach ($vm in ($config.VMs | Where-Object { Test-LabIPv4Address -Address $_.IPAddress })) {
    $exists = Get-DnsServerResourceRecord -ZoneName $zone -Name $vm.Name -RRType A -ErrorAction SilentlyContinue
    if (-not $exists -and $PSCmdlet.ShouldProcess("$($vm.Name).$zone", "Create A + PTR record -> $($vm.IPAddress)")) {
        Add-DnsServerResourceRecordA -ZoneName $zone -Name $vm.Name -IPv4Address $vm.IPAddress -CreatePtr
        Write-LabLog -Message "A/PTR record created: $($vm.Name) -> $($vm.IPAddress)"
    }
}
