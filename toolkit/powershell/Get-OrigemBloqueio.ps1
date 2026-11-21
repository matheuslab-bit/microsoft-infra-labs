<#
.SYNOPSIS
    Finds which computer is locking out a user account (event 4740 on the PDC emulator).
.DESCRIPTION
    When an account keeps getting locked, the cause is usually an old password saved somewhere: a phone
    with corporate e-mail, a mapped drive, a scheduled task or a service. Every lockout is logged on the
    PDC emulator with the name of the computer that sent the bad password. This script reads those events.
    Requires the ActiveDirectory module and permission to read the Security log on the DC.
.EXAMPLE
    .\Get-OrigemBloqueio.ps1 -UserName ana.ribeiro
.EXAMPLE
    .\Get-OrigemBloqueio.ps1 -Hours 4
#>
#Requires -Modules ActiveDirectory
[CmdletBinding()]
param(
    [string]$UserName,
    [ValidateRange(1, 168)][int]$Hours = 24
)

$pdc = (Get-ADDomain).PDCEmulator
$start = (Get-Date).AddHours(-$Hours).ToUniversalTime().ToString('o')
$xpath = "*[System[EventID=4740 and TimeCreated[@SystemTime>='$start']]]"
if ($UserName) {
    $xpath = "*[System[EventID=4740 and TimeCreated[@SystemTime>='$start']] and EventData[Data[@Name='TargetUserName']='$UserName']]"
}

Write-Verbose "Reading the Security log on $pdc"
$events = Get-WinEvent -ComputerName $pdc -LogName Security -FilterXPath $xpath -ErrorAction SilentlyContinue

if (-not $events) {
    Write-Information "No lockouts found on $pdc in the last $Hours hours." -InformationAction Continue
    return
}

foreach ($lockout in $events) {
    $data = ([xml]$lockout.ToXml()).Event.EventData.Data
    [pscustomobject]@{
        Horario  = $lockout.TimeCreated
        Usuario  = ($data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        # in event 4740 the caller computer name is stored in the TargetDomainName field
        ComputadorDeOrigem = ($data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        DC       = $pdc
    }
}
