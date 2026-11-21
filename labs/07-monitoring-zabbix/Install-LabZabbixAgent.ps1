<#
.SYNOPSIS
    Installs Zabbix Agent 2, copies the custom items and opens port 10050 only for the Zabbix server.
.DESCRIPTION
    Download the Agent 2 MSI (7.0 LTS) from zabbix.com first. The agent sends HostMetadata 'windows-lab',
    so an autoregistration action in Zabbix can add the host with the right template.
.EXAMPLE
    .\Install-LabZabbixAgent.ps1 -MsiPath C:\Temp\zabbix_agent2-7.0-windows-amd64-openssl.msi -WhatIf
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateScript({ Test-Path -Path $_ -PathType Leaf })][string]$MsiPath,
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$server = (Get-LabConfig -Path $ConfigPath).Monitoring.ZabbixServer
$installDir = 'C:\Program Files\Zabbix Agent 2'

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Install Zabbix Agent 2 pointing to $server")) {
    $arguments = @(
        '/i', "`"$MsiPath`"", '/qn', '/norestart',
        "SERVER=$server", "SERVERACTIVE=$server", "HOSTNAME=$env:COMPUTERNAME",
        'HOSTMETADATA=windows-lab', 'ENABLEPATH=1', "/l*v `"$env:TEMP\zabbix-agent2-install.log`""
    )
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -notin 0, 3010) { throw "msiexec failed with exit code $($process.ExitCode)." }
    Write-LabLog -Message 'Zabbix Agent 2 installed.'
}

$customConf = Join-Path -Path $PSScriptRoot -ChildPath 'agent2.d\windows-ad.conf'
$confDir = Join-Path -Path $installDir -ChildPath 'zabbix_agent2.d'
if ($PSCmdlet.ShouldProcess($confDir, 'Deploy custom UserParameters')) {
    New-Item -Path $confDir -ItemType Directory -Force | Out-Null
    Copy-Item -Path $customConf -Destination $confDir -Force
    $mainConf = Join-Path -Path $installDir -ChildPath 'zabbix_agent2.conf'
    $include = "Include=$confDir\*.conf"
    if (-not (Select-String -Path $mainConf -Pattern ([regex]::Escape($include)) -Quiet)) {
        Add-Content -Path $mainConf -Value $include
    }
    Restart-Service -Name 'Zabbix Agent 2'
}

if (-not (Get-NetFirewallRule -DisplayName 'Zabbix Agent 2 (from MON01)' -ErrorAction SilentlyContinue) -and
    $PSCmdlet.ShouldProcess('Windows Firewall', "Allow TCP 10050 only from $server")) {
    New-NetFirewallRule -DisplayName 'Zabbix Agent 2 (from MON01)' -Direction Inbound -Protocol TCP `
        -LocalPort 10050 -RemoteAddress $server -Action Allow -Profile Domain | Out-Null
    Write-LabLog -Message "Firewall rule created: TCP 10050 from $server."
}
