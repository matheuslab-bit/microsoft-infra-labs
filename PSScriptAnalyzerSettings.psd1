@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Lab scripts report progress through Write-LabLog (information stream); nothing to exclude yet.
    )
    Rules        = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.4')
        }
    }
}
