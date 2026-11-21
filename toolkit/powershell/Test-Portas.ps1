<#
.SYNOPSIS
    Tests TCP ports on one or more servers, with ready-made port lists for AD, web, RDP, SQL and VoIP.
.DESCRIPTION
    Answers the classic question "is it the firewall?". Uses a plain TCP connection with a timeout, so it
    works on Windows PowerShell 5.1 and PowerShell 7 (Windows and Linux).
    Presets:
      AD    53, 88, 135, 389, 445, 464, 636, 3268, 3269
      Web   80, 443
      RDP   3389
      SQL   1433
      VoIP  5060, 5061 (SIP over TCP and TLS)
.EXAMPLE
    .\Test-Portas.ps1 -ComputerName dc01.corp.lab.internal -Preset AD
.EXAMPLE
    .\Test-Portas.ps1 -ComputerName fs01,192.168.0.10 -Port 445,3389 -TimeoutMs 500
#>
[CmdletBinding(DefaultParameterSetName = 'Preset')]
param(
    [Parameter(Mandatory)][string[]]$ComputerName,
    [Parameter(ParameterSetName = 'Port', Mandatory)][ValidateRange(1, 65535)][int[]]$Port,
    [Parameter(ParameterSetName = 'Preset')][ValidateSet('AD', 'Web', 'RDP', 'SQL', 'VoIP')][string]$Preset = 'Web',
    [ValidateRange(100, 10000)][int]$TimeoutMs = 1000
)

$presets = @{
    AD   = 53, 88, 135, 389, 445, 464, 636, 3268, 3269
    Web  = 80, 443
    RDP  = 3389
    SQL  = 1433
    VoIP = 5060, 5061
}
if ($PSCmdlet.ParameterSetName -eq 'Preset') { $Port = $presets[$Preset] }

foreach ($computer in $ComputerName) {
    foreach ($p in $Port) {
        $client = New-Object -TypeName System.Net.Sockets.TcpClient
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $open = $false
        try {
            $task = $client.ConnectAsync($computer, $p)
            $open = $task.Wait($TimeoutMs) -and $client.Connected
        } catch {
            $open = $false
        } finally {
            $watch.Stop()
            $client.Dispose()
        }
        [pscustomobject]@{
            Computador = $computer
            Porta      = $p
            Status     = if ($open) { 'Aberta' } else { 'Fechada ou filtrada' }
            TempoMs    = if ($open) { $watch.ElapsedMilliseconds } else { $null }
        }
    }
}
