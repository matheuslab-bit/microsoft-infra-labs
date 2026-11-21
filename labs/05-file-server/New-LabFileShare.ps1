<#
.SYNOPSIS
    Creates the department shares with NTFS permissions given through groups (AGDLP).
.DESCRIPTION
    For each share: creates DL_Share_<Name>_R and _M groups, adds the department group to _M,
    sets NTFS permissions without inheritance and publishes the share with access-based enumeration
    (users only see folders they can open).
.EXAMPLE
    .\New-LabFileShare.ps1 -WhatIf
#>
#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory, SmbShare
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$netbios = $config.Domain.NetBiosName
$rootDn = 'OU={0},{1}' -f $config.Domain.RootOuName, (ConvertTo-LabDistinguishedName -DomainFqdn $config.Domain.Fqdn)
$resourceOu = "OU=Recursos,OU=Grupos,$rootDn"

function New-LabDomainLocalGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name, [string]$Description)
    if (-not (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue) -and
        $PSCmdlet.ShouldProcess($Name, 'Create domain local group')) {
        New-ADGroup -Name $Name -GroupScope DomainLocal -GroupCategory Security -Path $resourceOu -Description $Description
        Write-LabLog -Message "Group created: $Name"
    }
}

foreach ($share in $config.Shares) {
    $readGroup = "DL_Share_$($share.Name)_R"
    $modifyGroup = "DL_Share_$($share.Name)_M"
    New-LabDomainLocalGroup -Name $readGroup -Description "Leitura em \\FS01\$($share.Name)"
    New-LabDomainLocalGroup -Name $modifyGroup -Description "Modificacao em \\FS01\$($share.Name)"

    $member = if ($share.Department -eq 'ALL') { 'Domain Users' } else { "GG_$($share.Department)" }
    if ($PSCmdlet.ShouldProcess($modifyGroup, "Nest $member (AGDLP)")) {
        Add-ADGroupMember -Identity $modifyGroup -Members $member
    }

    if (-not (Test-Path -Path $share.Path) -and $PSCmdlet.ShouldProcess($share.Path, 'Create folder')) {
        New-Item -Path $share.Path -ItemType Directory -Force | Out-Null
    }

    if ($PSCmdlet.ShouldProcess($share.Path, 'Set NTFS permissions (inheritance disabled)')) {
        $acl = New-Object -TypeName System.Security.AccessControl.DirectorySecurity
        $acl.SetAccessRuleProtection($true, $false)
        $inherit = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
        $propagation = [System.Security.AccessControl.PropagationFlags]::None
        $rules = @(
            @('NT AUTHORITY\SYSTEM', 'FullControl'),
            @('BUILTIN\Administrators', 'FullControl'),
            @("$netbios\$modifyGroup", 'Modify'),
            @("$netbios\$readGroup", 'ReadAndExecute')
        )
        foreach ($rule in $rules) {
            $acl.AddAccessRule((New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $rule[0], $rule[1], $inherit, $propagation, 'Allow'))
        }
        Set-Acl -Path $share.Path -AclObject $acl
        Write-LabLog -Message "NTFS permissions applied to $($share.Path)."
    }

    if (-not (Get-SmbShare -Name $share.Name -ErrorAction SilentlyContinue) -and
        $PSCmdlet.ShouldProcess($share.Name, "Publish SMB share for $($share.Path)")) {
        New-SmbShare -Name $share.Name -Path $share.Path -ChangeAccess 'NT AUTHORITY\Authenticated Users' `
            -FullAccess 'BUILTIN\Administrators' -FolderEnumerationMode AccessBased -CachingMode None | Out-Null
        Write-LabLog -Message "Share published: \\$env:COMPUTERNAME\$($share.Name)"
    }
}
