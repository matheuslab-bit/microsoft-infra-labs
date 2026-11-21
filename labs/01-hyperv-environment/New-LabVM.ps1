<#
.SYNOPSIS
    Creates the lab VMs listed in config/lab.psd1.
.DESCRIPTION
    Generation 2 VMs with Secure Boot, dynamic memory and a dynamic VHDX. Windows VMs also get a virtual TPM.
    Linux VMs use the Microsoft UEFI CA template so they can boot with Secure Boot on.
    VMs that already exist are skipped.
.EXAMPLE
    .\New-LabVM.ps1 -Name DC01,CL01 -WhatIf
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Name,
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$vms = $config.VMs | Where-Object { -not $Name -or $Name -contains $_.Name }

foreach ($vm in $vms) {
    if (Get-VM -Name $vm.Name -ErrorAction SilentlyContinue) {
        Write-LabLog -Message "VM '$($vm.Name)' already exists - skipped."
        continue
    }
    $vmRoot = Join-Path -Path $config.Lab.VMPath -ChildPath $vm.Name
    $vhdPath = Join-Path -Path $vmRoot -ChildPath "$($vm.Name).vhdx"
    $isoPath = Join-Path -Path $config.Lab.IsoPath -ChildPath $vm.Iso
    if (-not (Test-Path -Path $isoPath)) {
        Write-LabLog -Level Warning -Message "ISO not found for $($vm.Name): $isoPath - skipped."
        continue
    }
    if (-not $PSCmdlet.ShouldProcess($vm.Name, "Create Gen2 VM ($($vm.ProcessorCount) vCPU, $($vm.MemoryGB) GB RAM, $($vm.DiskGB) GB disk)")) {
        continue
    }

    New-Item -Path $vmRoot -ItemType Directory -Force | Out-Null
    New-VHD -Path $vhdPath -SizeBytes ([int64]$vm.DiskGB * 1GB) -Dynamic | Out-Null
    New-VM -Name $vm.Name -Generation 2 -MemoryStartupBytes ([int64]$vm.MemoryGB * 1GB) -VHDPath $vhdPath `
        -SwitchName $config.Network.SwitchName -Path $config.Lab.VMPath | Out-Null

    Set-VM -Name $vm.Name -ProcessorCount $vm.ProcessorCount -DynamicMemory `
        -MemoryMinimumBytes 1GB -MemoryMaximumBytes ([int64]$vm.MemoryGB * 1GB) `
        -CheckpointType Production -AutomaticCheckpointsEnabled $false
    Add-VMDvdDrive -VMName $vm.Name -Path $isoPath

    if ($vm.Role -eq 'Monitoring') {
        Set-VMFirmware -VMName $vm.Name -SecureBootTemplate 'MicrosoftUEFICertificateAuthority'
    } else {
        Set-VMKeyProtector -VMName $vm.Name -NewLocalKeyProtector
        Enable-VMTPM -VMName $vm.Name
    }
    Set-VMFirmware -VMName $vm.Name -FirstBootDevice (Get-VMDvdDrive -VMName $vm.Name)
    Write-LabLog -Message "VM '$($vm.Name)' created at $vmRoot."
}
