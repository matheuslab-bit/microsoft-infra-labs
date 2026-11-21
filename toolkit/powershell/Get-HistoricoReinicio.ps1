<#
.SYNOPSIS
    Shows when a server restarted, who restarted it and whether it was an unexpected shutdown.
.DESCRIPTION
    Reads the System log for:
      1074  planned restart or shutdown (shows the user and the reason)
      6008  previous shutdown was unexpected
      41    Kernel-Power: rebooted without a clean shutdown (power loss, freeze)
      6005  event log service started (machine came up)
    Useful for the "the server rebooted by itself" ticket.
.EXAMPLE
    .\Get-HistoricoReinicio.ps1 -ComputerName FS01 -Days 30
#>
[CmdletBinding()]
param(
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [ValidateRange(1, 365)][int]$Days = 7
)

$labels = @{
    1074 = 'Reinicio/desligamento planejado'
    6008 = 'Desligamento inesperado'
    41   = 'Reinicio sem desligamento limpo (Kernel-Power)'
    6005 = 'Maquina ligou'
}

foreach ($computer in $ComputerName) {
    $filter = @{ LogName = 'System'; Id = 1074, 6008, 41, 6005; StartTime = (Get-Date).AddDays(-$Days) }
    try {
        Get-WinEvent -ComputerName $computer -FilterHashtable $filter -ErrorAction Stop |
            Sort-Object -Property TimeCreated -Descending |
            ForEach-Object {
                [pscustomobject]@{
                    Computador = $computer
                    Horario    = $_.TimeCreated
                    Evento     = $_.Id
                    Tipo       = $labels[$_.Id]
                    Detalhe    = ($_.Message -split "`n")[0].Trim()
                }
            }
    } catch {
        Write-Warning "$computer : $($_.Exception.Message)"
    }
}
