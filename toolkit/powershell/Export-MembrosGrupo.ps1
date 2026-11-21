<#
.SYNOPSIS
    Exports who is in each AD group (including nested members) to CSV, for periodic access reviews.
.DESCRIPTION
    Access reviews ("who has access to what") are a common audit requirement. This script lists every
    member of the selected groups, follows nested groups and marks disabled accounts, so the manager
    of each area can review and sign off.
.EXAMPLE
    .\Export-MembrosGrupo.ps1 -Filter 'DL_Share_*' -OutputPath .\revisao-acessos.csv
.EXAMPLE
    .\Export-MembrosGrupo.ps1 -Group 'Domain Admins','GG_TI'
#>
#Requires -Modules ActiveDirectory
[CmdletBinding(DefaultParameterSetName = 'Filter')]
param(
    [Parameter(ParameterSetName = 'Name', Mandatory)][string[]]$Group,
    [Parameter(ParameterSetName = 'Filter')][string]$Filter = 'GG_*',
    [string]$OutputPath
)

$groups = if ($PSCmdlet.ParameterSetName -eq 'Name') {
    $Group | ForEach-Object { Get-ADGroup -Identity $_ }
} else {
    Get-ADGroup -Filter "Name -like '$Filter'"
}

$rows = foreach ($g in $groups) {
    $members = Get-ADGroupMember -Identity $g -Recursive | Where-Object { $_.objectClass -eq 'user' }
    if (-not $members) {
        [pscustomobject]@{ Grupo = $g.Name; Usuario = '(vazio)'; Nome = ''; Ativo = ''; UltimoLogon = '' }
        continue
    }
    foreach ($m in $members) {
        $user = Get-ADUser -Identity $m.SamAccountName -Properties Enabled, LastLogonDate, DisplayName
        [pscustomobject]@{
            Grupo       = $g.Name
            Usuario     = $user.SamAccountName
            Nome        = $user.DisplayName
            Ativo       = $user.Enabled
            UltimoLogon = $user.LastLogonDate
        }
    }
}

if ($OutputPath) {
    $rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Information "Access review saved to $OutputPath ($(@($rows).Count) rows)." -InformationAction Continue
}
$rows
