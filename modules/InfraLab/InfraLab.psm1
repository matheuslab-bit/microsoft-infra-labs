Set-StrictMode -Version Latest

function Write-LabLog {
    <#
    .SYNOPSIS
        Writes a timestamped log line to the information stream and, optionally, to a log file.
    .EXAMPLE
        Write-LabLog -Message 'OU created' -Level Info -LogPath C:\Logs\lab.log
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')][string]$Level = 'Info',
        [string]$LogPath
    )
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level.ToUpperInvariant(), $Message
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error'   { Write-Error $Message -ErrorAction Continue }
        default   { Write-Information $line -InformationAction Continue }
    }
    if ($LogPath) {
        $dir = Split-Path -Path $LogPath -Parent
        if ($dir -and -not (Test-Path -Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        Add-Content -Path $LogPath -Value $line -Encoding UTF8
    }
}

function Get-LabConfig {
    <#
    .SYNOPSIS
        Loads and validates the lab definition file (config/lab.psd1).
    .EXAMPLE
        $config = Get-LabConfig
    #>
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\config\lab.psd1')
    )
    if (-not (Test-Path -Path $Path)) { throw "Lab configuration not found: $Path" }
    $config = Import-PowerShellDataFile -Path $Path
    foreach ($key in 'Network', 'Domain', 'VMs', 'Dhcp', 'OrganizationalUnits', 'Departments', 'Shares', 'Backup') {
        if (-not $config.ContainsKey($key)) { throw "Lab configuration is missing the '$key' section." }
    }
    $config
}

function Assert-LabAdministrator {
    <#
    .SYNOPSIS
        Throws when the current Windows session is not elevated.
    #>
    [CmdletBinding()]
    param()
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must run from an elevated PowerShell session (Run as Administrator).'
    }
}

function ConvertTo-LabSamAccountName {
    <#
    .SYNOPSIS
        Builds a 'given.surname' logon name without diacritics, limited to 20 characters (sAMAccountName limit).
    .EXAMPLE
        ConvertTo-LabSamAccountName -GivenName 'Joao' -Surname 'Conceicao'   # joao.conceicao
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$GivenName,
        [Parameter(Mandatory)][string]$Surname
    )
    $raw = '{0}.{1}' -f $GivenName.Trim().Split(' ')[0], $Surname.Trim().Split(' ')[-1]
    $normalized = $raw.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object -TypeName System.Text.StringBuilder
    foreach ($char in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($char) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($char)
        }
    }
    $clean = ($builder.ToString().ToLowerInvariant() -replace '[^a-z0-9\.]', '')
    if ($clean.Length -gt 20) { $clean = $clean.Substring(0, 20).TrimEnd('.') }
    $clean
}

function Test-LabIPv4Address {
    <#
    .SYNOPSIS
        Returns $true when the value is a dotted-quad IPv4 address.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Address)
    $parsed = $null
    ($Address -match '^(\d{1,3}\.){3}\d{1,3}$') -and [Net.IPAddress]::TryParse($Address, [ref]$parsed)
}

function ConvertTo-LabUInt32 {
    [CmdletBinding()]
    [OutputType([uint32])]
    param([Parameter(Mandatory)][string]$Address)
    $bytes = ([Net.IPAddress]::Parse($Address)).GetAddressBytes()
    [Array]::Reverse($bytes)
    [BitConverter]::ToUInt32($bytes, 0)
}

function ConvertFrom-LabUInt32 {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][uint32]$Value)
    $bytes = [BitConverter]::GetBytes($Value)
    [Array]::Reverse($bytes)
    ([Net.IPAddress]::new($bytes)).ToString()
}

function Get-LabIPv4Network {
    <#
    .SYNOPSIS
        Calculates network, broadcast, mask and usable host range for an IPv4 address and prefix length.
    .EXAMPLE
        Get-LabIPv4Network -Address 10.50.0.10 -PrefixLength 24
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateScript({ Test-LabIPv4Address -Address $_ })][string]$Address,
        [Parameter(Mandatory)][ValidateRange(8, 30)][int]$PrefixLength
    )
    $ip = ConvertTo-LabUInt32 -Address $Address
    $mask = [uint32]([math]::Pow(2, 32) - [math]::Pow(2, 32 - $PrefixLength))
    $network = $ip -band $mask
    $broadcast = $network + [uint32]([math]::Pow(2, 32 - $PrefixLength) - 1)
    [pscustomobject]@{
        Network      = ConvertFrom-LabUInt32 -Value $network
        Broadcast    = ConvertFrom-LabUInt32 -Value $broadcast
        SubnetMask   = ConvertFrom-LabUInt32 -Value $mask
        PrefixLength = $PrefixLength
        FirstHost    = ConvertFrom-LabUInt32 -Value ($network + 1)
        LastHost     = ConvertFrom-LabUInt32 -Value ($broadcast - 1)
        UsableHosts  = [int]($broadcast - $network - 1)
    }
}

function Test-LabAddressInRange {
    <#
    .SYNOPSIS
        Returns $true when an IPv4 address lies between StartAddress and EndAddress (inclusive).
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$Address,
        [Parameter(Mandatory)][string]$StartAddress,
        [Parameter(Mandatory)][string]$EndAddress
    )
    $value = ConvertTo-LabUInt32 -Address $Address
    ($value -ge (ConvertTo-LabUInt32 -Address $StartAddress)) -and ($value -le (ConvertTo-LabUInt32 -Address $EndAddress))
}

function ConvertTo-LabDistinguishedName {
    <#
    .SYNOPSIS
        Converts an FQDN such as corp.lab.internal into DC=corp,DC=lab,DC=internal.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$DomainFqdn)
    ($DomainFqdn.Split('.') | ForEach-Object { "DC=$_" }) -join ','
}

Export-ModuleMember -Function Write-LabLog, Get-LabConfig, Assert-LabAdministrator, ConvertTo-LabSamAccountName,
    Test-LabIPv4Address, Get-LabIPv4Network, Test-LabAddressInRange, ConvertTo-LabDistinguishedName
