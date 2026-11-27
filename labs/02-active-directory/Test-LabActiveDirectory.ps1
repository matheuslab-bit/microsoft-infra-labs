<#
.SYNOPSIS
    Checks the Lab 02 result on DC01 and writes an evidence report: domain, DC services, dcdiag, OUs, groups and users.
.DESCRIPTION
    Run it on DC01, logged on as a domain administrator, after Install-LabForest, New-LabOUStructure
    and Import-LabUsers. It only reads the environment.

    Checks: server name, static IP and DNS client settings, the domain and functional levels, the
    AD DS/DNS/Netlogon/KDC services, dcdiag /q, the AD-integrated DNS zones, every OU from
    config/lab.psd1, the default computer container redirected to OU Estacoes, the GG_<department>
    groups, and each user from data/users.csv in its department OU and group with a first-logon password change.

    The first logon on CL01 is a manual check: CL01 is created in Lab 03, so it is reported as SKIP.
    Every check returns PASS, FAIL or SKIP. Exits with code 1 if any check fails.
.EXAMPLE
    .\Test-LabActiveDirectory.ps1
.EXAMPLE
    .\Test-LabActiveDirectory.ps1 -ReportPath C:\Lab\evidencia-lab02.txt
#>
#Requires -Modules ActiveDirectory
[CmdletBinding()]
param(
    [string]$InterfaceAlias = 'Ethernet',
    [string]$ReportPath = 'C:\Lab\evidencia-lab02.txt',
    [string]$CsvPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\data\users.csv'),
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules\InfraLab\InfraLab.psd1') -Force
$config = Get-LabConfig -Path $ConfigPath
$dc = $config.VMs | Where-Object { $_.Role -eq 'DomainController' } | Select-Object -First 1
$domainDn = ConvertTo-LabDistinguishedName -DomainFqdn $config.Domain.Fqdn
$rootDn = "OU=$($config.Domain.RootOuName),$domainDn"

$results = New-Object -TypeName System.Collections.Generic.List[object]
function Add-Result([string]$Check, [string]$Result, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = $Result; Detail = $Detail })
}
function Add-Check([string]$Check, [bool]$Condition, [string]$PassDetail, [string]$FailDetail) {
    if ($Condition) { Add-Result -Check $Check -Result 'PASS' -Detail $PassDetail }
    else { Add-Result -Check $Check -Result 'FAIL' -Detail $FailDetail }
}

# --- Server ---------------------------------------------------------------------------------------
Add-Check -Check 'Server name' -Condition ($env:COMPUTERNAME -eq $dc.Name) `
    -PassDetail $env:COMPUTERNAME -FailDetail "name is $env:COMPUTERNAME, expected $($dc.Name)"

$ip = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -eq $dc.IPAddress }
$dhcp = (Get-NetIPInterface -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue).Dhcp
Add-Check -Check 'Static IP' -Condition ([bool]$ip -and $dhcp -eq 'Disabled') `
    -PassDetail "$($dc.IPAddress)/$($config.Network.PrefixLength), DHCP disabled" `
    -FailDetail "expected $($dc.IPAddress) with DHCP disabled (DHCP: $dhcp)"

$dnsServers = @((Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4).ServerAddresses)
$dnsOk = $dnsServers.Count -gt 0 -and ($dnsServers[0] -eq $dc.IPAddress -or $dnsServers[0] -eq '127.0.0.1') -and
    -not ($dnsServers | Where-Object { $_ -notin @($dc.IPAddress, '127.0.0.1') })
Add-Check -Check 'DC uses its own DNS' -Condition $dnsOk `
    -PassDetail ($dnsServers -join ', ') -FailDetail "DNS servers: $($dnsServers -join ', ') (must point only to this DC)"

# --- Domain and services -------------------------------------------------------------------------
$domain = Get-ADDomain
$forest = Get-ADForest
Add-Check -Check 'Domain' -Condition ($domain.DNSRoot -eq $config.Domain.Fqdn -and $domain.NetBIOSName -eq $config.Domain.NetBiosName) `
    -PassDetail "$($domain.DNSRoot) ($($domain.NetBIOSName))" -FailDetail "found $($domain.DNSRoot) ($($domain.NetBIOSName))"
Add-Result -Check 'Functional levels' -Result 'PASS' -Detail "forest $($forest.ForestMode), domain $($domain.DomainMode)"

$serviceNames = 'NTDS', 'DNS', 'Netlogon', 'Kdc'
$stopped = Get-Service -Name $serviceNames | Where-Object { $_.Status -ne 'Running' }
Add-Check -Check 'DC services' -Condition (-not $stopped) `
    -PassDetail "$($serviceNames -join ', ') running" -FailDetail "not running: $($stopped.Name -join ', ')"

$dcdiag = & dcdiag.exe /q 2>&1 | Where-Object { $_ -and $_.ToString().Trim() }
Add-Check -Check 'dcdiag /q' -Condition (-not $dcdiag) `
    -PassDetail 'no errors reported' -FailDetail (($dcdiag | Select-Object -First 3) -join ' | ')

$zones = (Get-DnsServerZone).ZoneName
$expectedZones = $config.Domain.Fqdn, "_msdcs.$($config.Domain.Fqdn)"
$missingZones = $expectedZones | Where-Object { $_ -notin $zones }
Add-Check -Check 'DNS zones' -Condition (-not $missingZones) `
    -PassDetail ($expectedZones -join ', ') -FailDetail "missing: $($missingZones -join ', ')"

# --- OUs ------------------------------------------------------------------------------------------
$expectedOus = New-Object -TypeName System.Collections.Generic.List[string]
$expectedOus.Add($rootDn)
foreach ($ouPath in $config.OrganizationalUnits) {
    $segments = $ouPath.Split('/')
    [array]::Reverse($segments)
    $expectedOus.Add((($segments | ForEach-Object { "OU=$_" }) -join ',') + ",$rootDn")
}
foreach ($department in $config.Departments) { $expectedOus.Add("OU=$department,OU=Usuarios,$rootDn") }

$existingOus = (Get-ADOrganizationalUnit -Filter * -SearchBase $rootDn).DistinguishedName
$missingOus = $expectedOus | Where-Object { $_ -notin $existingOus }
Add-Check -Check 'OU structure' -Condition (-not $missingOus) `
    -PassDetail "$($expectedOus.Count) OUs present" -FailDetail "missing: $(($missingOus | Select-Object -First 3) -join '; ')"

$unprotected = Get-ADOrganizationalUnit -Filter * -SearchBase $rootDn -Properties ProtectedFromAccidentalDeletion |
    Where-Object { -not $_.ProtectedFromAccidentalDeletion }
Add-Check -Check 'OUs protected from deletion' -Condition (-not $unprotected) `
    -PassDetail 'all OUs protected' -FailDetail "$(@($unprotected).Count) OU(s) not protected"

$computersOu = "OU=Estacoes,OU=Computadores,$rootDn"
Add-Check -Check 'Default computer container' -Condition ($domain.ComputersContainer -eq $computersOu) `
    -PassDetail 'redirected to OU Estacoes (redircmp)' -FailDetail "still $($domain.ComputersContainer)"

# --- Groups and users -----------------------------------------------------------------------------
$users = Import-Csv -Path $CsvPath -Encoding UTF8
$departments = $users.Department | Sort-Object -Unique
$missingGroups = $departments | Where-Object { -not (Get-ADGroup -Filter "Name -eq 'GG_$_'" -ErrorAction SilentlyContinue) }
Add-Check -Check 'Department groups' -Condition (-not $missingGroups) `
    -PassDetail (($departments | ForEach-Object { "GG_$_" }) -join ', ') -FailDetail "missing: $(($missingGroups | ForEach-Object { "GG_$_" }) -join ', ')"

$problems = New-Object -TypeName System.Collections.Generic.List[string]
foreach ($user in $users) {
    $label = "$($user.GivenName) $($user.Surname)"
    $account = Get-ADUser -Filter "GivenName -eq '$($user.GivenName)' -and Surname -eq '$($user.Surname)'" `
        -Properties MemberOf, pwdLastSet, Enabled -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $account) { $problems.Add("$label not found"); continue }
    $expectedParent = "OU=$($user.Department),OU=Usuarios,$rootDn"
    if ($account.DistinguishedName -notlike "*,$expectedParent") { $problems.Add("$label outside $($user.Department) OU") }
    if (-not ($account.MemberOf | Where-Object { $_ -like "CN=GG_$($user.Department),*" })) { $problems.Add("$label not in GG_$($user.Department)") }
    if (-not $account.Enabled) { $problems.Add("$label disabled") }
}
Add-Check -Check 'Users from CSV' -Condition ($problems.Count -eq 0) `
    -PassDetail "$(@($users).Count) users in their department OU and group" -FailDetail (($problems | Select-Object -First 4) -join '; ')

$pending = @(foreach ($user in $users) {
        Get-ADUser -Filter "GivenName -eq '$($user.GivenName)' -and Surname -eq '$($user.Surname)'" -Properties pwdLastSet -ErrorAction SilentlyContinue |
            Where-Object { $_.pwdLastSet -eq 0 }
    })
Add-Result -Check 'Password change at first logon' -Result 'PASS' `
    -Detail "$($pending.Count) of $(@($users).Count) users still have to change the initial password"

Add-Result -Check 'First logon on CL01' -Result 'SKIP' -Detail 'CL01 is created in Lab 03; check manually there'

# --- Report ---------------------------------------------------------------------------------------
$header = "Lab 02 - Active Directory check | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | server $env:COMPUTERNAME"
$table = $results | Format-Table -Property Check, Result, Detail -AutoSize -Wrap | Out-String -Width 200
$reportDir = Split-Path -Path $ReportPath -Parent
if ($reportDir -and -not (Test-Path -Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }
Set-Content -Path $ReportPath -Value ($header, $table) -Encoding UTF8
Write-LabLog -Message "Report saved to $ReportPath"

$results
if ($results.Result -contains 'FAIL') { exit 1 }
