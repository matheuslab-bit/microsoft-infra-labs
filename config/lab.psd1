@{
    # Lab settings. Every script reads this file.
    Lab = @{
        Name   = 'CORP-LAB'
        VMPath = 'C:\HyperV\Lab'
        IsoPath = 'C:\HyperV\ISO'
    }

    Network = @{
        SwitchName   = 'LabInternal'
        NatName      = 'LabNAT'
        Prefix       = '10.50.0.0'
        PrefixLength = 24
        Gateway      = '10.50.0.1'
    }

    Domain = @{
        Fqdn            = 'corp.lab.internal'
        NetBiosName     = 'CORP'
        ForestMode      = 'WinThreshold'
        DnsForwarders   = @('1.1.1.1', '8.8.8.8')
        RootOuName      = 'CORP'
    }

    VMs = @(
        @{ Name = 'DC01'; Role = 'DomainController'; IPAddress = '10.50.0.10'; MemoryGB = 4; ProcessorCount = 2; DiskGB = 60; Iso = 'WindowsServer2022_Eval.iso' }
        @{ Name = 'FS01'; Role = 'FileServer';       IPAddress = '10.50.0.20'; MemoryGB = 4; ProcessorCount = 2; DiskGB = 80; Iso = 'WindowsServer2022_Eval.iso' }
        @{ Name = 'MON01'; Role = 'Monitoring';      IPAddress = '10.50.0.30'; MemoryGB = 4; ProcessorCount = 2; DiskGB = 40; Iso = 'ubuntu-24.04-live-server-amd64.iso' }
        @{ Name = 'CL01'; Role = 'Client';           IPAddress = 'DHCP';       MemoryGB = 4; ProcessorCount = 2; DiskGB = 60; Iso = 'Windows11_Enterprise_Eval.iso' }
    )

    Dhcp = @{
        ScopeName     = 'LAB-Estacoes'
        StartRange    = '10.50.0.100'
        EndRange      = '10.50.0.200'
        LeaseDuration = '08:00:00'
        Router        = '10.50.0.1'
        DnsServers    = @('10.50.0.10')
    }

    # users, computers and groups in separate OUs, so each one can get its own GPO
    OrganizationalUnits = @(
        'Usuarios'
        'Computadores'
        'Computadores/Estacoes'
        'Computadores/Servidores'
        'Grupos'
        'Grupos/Seguranca'
        'Grupos/Recursos'
        'Contas-de-Servico'
        'Desativados'
    )

    Departments = @('TI', 'Financeiro', 'Qualidade', 'Producao', 'RH')

    # AGDLP: user -> department group (GG_) -> share permission group (DL_)
    Shares = @(
        @{ Name = 'Financeiro'; Path = 'D:\Shares\Financeiro'; Department = 'Financeiro' }
        @{ Name = 'Qualidade';  Path = 'D:\Shares\Qualidade';  Department = 'Qualidade' }
        @{ Name = 'Publico';    Path = 'D:\Shares\Publico';    Department = 'ALL' }
    )

    Backup = @{
        TargetPath    = 'E:\Backups'
        RetentionDays = 14
        Sources       = @('D:\Shares')
    }

    Monitoring = @{
        ZabbixServer = '10.50.0.30'
    }
}
