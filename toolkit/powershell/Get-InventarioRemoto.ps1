<#
.SYNOPSIS
    Collects hardware and OS inventory from many computers at once and saves it to CSV.
.DESCRIPTION
    For each computer: model, serial number, OS and build, CPU, RAM, C: free space, IP, last boot and the
    logged-on user. Computers that do not answer are listed as Offline instead of stopping the script.
    Uses CIM over WinRM, which is on by default in domain-joined Windows Server.
.EXAMPLE
    .\Get-InventarioRemoto.ps1 -ComputerName PC01,PC02 -OutputPath C:\Temp\inventario.csv
.EXAMPLE
    Get-ADComputer -Filter * -SearchBase 'OU=Estacoes,OU=Computadores,OU=CORP,DC=corp,DC=lab,DC=internal' |
        Select-Object -ExpandProperty Name | .\Get-InventarioRemoto.ps1 -OutputPath .\estacoes.csv
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)][string[]]$ComputerName = $env:COMPUTERNAME,
    [string]$OutputPath
)

begin {
    $results = New-Object -TypeName System.Collections.Generic.List[object]
}

process {
    foreach ($computer in $ComputerName) {
        Write-Verbose "Collecting $computer"
        try {
            $session = New-CimSession -ComputerName $computer -OperationTimeoutSec 15 -ErrorAction Stop
            $system = Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem
            $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
            $bios = Get-CimInstance -CimSession $session -ClassName Win32_BIOS
            $cpu = Get-CimInstance -CimSession $session -ClassName Win32_Processor | Select-Object -First 1
            $disk = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
            $ip = Get-CimInstance -CimSession $session -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = True' |
                ForEach-Object { $_.IPAddress } | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1
            $results.Add([pscustomobject]@{
                Computador    = $computer
                Status        = 'Online'
                Fabricante    = $system.Manufacturer
                Modelo        = $system.Model
                NumeroSerie   = $bios.SerialNumber
                Sistema       = $os.Caption
                Build         = $os.BuildNumber
                Processador   = $cpu.Name.Trim()
                MemoriaGB     = [math]::Round($system.TotalPhysicalMemory / 1GB, 1)
                DiscoCLivreGB = [math]::Round($disk.FreeSpace / 1GB, 1)
                DiscoCTotalGB = [math]::Round($disk.Size / 1GB, 1)
                IP            = $ip
                UltimoBoot    = $os.LastBootUpTime
                UsuarioLogado = $system.UserName
            })
            Remove-CimSession -CimSession $session
        } catch {
            $results.Add([pscustomobject]@{ Computador = $computer; Status = "Offline: $($_.Exception.Message)" })
        }
    }
}

end {
    if ($OutputPath) {
        $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Information "Inventory saved to $OutputPath ($($results.Count) computers)." -InformationAction Continue
    }
    $results
}
