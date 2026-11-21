@{
    RootModule        = 'InfraLab.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '6f3c2a91-4b7e-4d2a-9c1f-2e8b5d7a3c10'
    Author            = 'Matheus Silva'
    Description       = 'Shared helpers for the Microsoft infrastructure labs (logging, configuration, naming and IPv4 math).'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Write-LabLog', 'Get-LabConfig', 'Assert-LabAdministrator', 'ConvertTo-LabSamAccountName',
        'Test-LabIPv4Address', 'Get-LabIPv4Network', 'Test-LabAddressInRange', 'ConvertTo-LabDistinguishedName'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
