<#
.SYNOPSIS
    Creates the OU structure, with one OU per department.
.DESCRIPTION
    Users, computers and groups get separate OUs so GPOs can target each one.
    OUs are protected from accidental deletion. Safe to run again.
.EXAMPLE
    .\New-LabOUStructure.ps1 -WhatIf
#>
#Requires -Modules ActiveDirectory
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$domainDn = ConvertTo-LabDistinguishedName -DomainFqdn $config.Domain.Fqdn
$rootName = $config.Domain.RootOuName

function New-LabOU {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Name, [string]$ParentDn)
    $dn = "OU=$Name,$ParentDn"
    if (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue) {
        Write-LabLog -Message "OU exists: $dn"
    } elseif ($PSCmdlet.ShouldProcess($dn, 'Create OU')) {
        New-ADOrganizationalUnit -Name $Name -Path $ParentDn -ProtectedFromAccidentalDeletion $true
        Write-LabLog -Message "OU created: $dn"
    }
    $dn
}

$rootDn = New-LabOU -Name $rootName -ParentDn $domainDn

foreach ($ouPath in $config.OrganizationalUnits) {
    $parent = $rootDn
    foreach ($segment in $ouPath.Split('/')) {
        $parent = New-LabOU -Name $segment -ParentDn $parent
    }
}

foreach ($department in $config.Departments) {
    New-LabOU -Name $department -ParentDn "OU=Usuarios,$rootDn" | Out-Null
}

# new computers go to OU Estacoes instead of the default Computers container (GPOs cannot be linked there)
if ($PSCmdlet.ShouldProcess($domainDn, 'Redirect default computer container to OU Estacoes')) {
    & redircmp.exe "OU=Estacoes,OU=Computadores,$rootDn" | Out-Null
}
