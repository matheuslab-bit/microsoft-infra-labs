BeforeDiscovery {
    $repoRoot = Split-Path -Path $PSScriptRoot -Parent
    $scripts = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath 'labs') -Filter '*.ps1' -Recurse |
        ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
    # Scripts whose verb changes the environment must support -WhatIf/-Confirm.
    $changingVerbs = 'New', 'Set', 'Install', 'Enable', 'Invoke', 'Import', 'Backup', 'Remove'
    $changingScripts = $scripts | Where-Object { $changingVerbs -contains ($_.Name -split '-')[0] }
}

BeforeAll {
    $repoRoot = Split-Path -Path $PSScriptRoot -Parent
    Import-Module (Join-Path -Path $repoRoot -ChildPath 'modules\InfraLab\InfraLab.psd1') -Force
    function Get-ScriptAst([string]$Path) {
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        [pscustomobject]@{ Ast = $ast; Errors = $errors }
    }
}

Describe 'Lab script <Name>' -ForEach $scripts {
    It 'parses without syntax errors' {
        (Get-ScriptAst -Path $Path).Errors | Should -BeNullOrEmpty
    }
    It 'has comment-based help with a synopsis' {
        $help = (Get-ScriptAst -Path $Path).Ast.GetHelpContent()
        $help | Should -Not -BeNullOrEmpty
        $help.Synopsis | Should -Not -BeNullOrEmpty
    }
    It 'is an advanced script ([CmdletBinding()])' {
        $attributes = (Get-ScriptAst -Path $Path).Ast.ParamBlock.Attributes.TypeName.Name
        $attributes | Should -Contain 'CmdletBinding'
    }
    It 'is ASCII-only (safe for Windows PowerShell 5.1 without BOM)' {
        [IO.File]::ReadAllBytes($Path) | Where-Object { $_ -gt 127 } | Should -BeNullOrEmpty
    }
    It 'contains no hard-coded plain-text password' {
        Get-Content -Path $Path -Raw | Should -Not -Match "ConvertTo-SecureString\s+(-String\s+)?['""]"
    }
}

Describe 'State-changing script <Name>' -ForEach $changingScripts {
    It 'declares SupportsShouldProcess (supports -WhatIf)' {
        $binding = (Get-ScriptAst -Path $Path).Ast.ParamBlock.Attributes | Where-Object { $_.TypeName.Name -eq 'CmdletBinding' }
        $binding.NamedArguments.ArgumentName | Should -Contain 'SupportsShouldProcess'
    }
}

Describe 'Lab configuration (config/lab.psd1)' {
    BeforeAll {
        $config = Get-LabConfig -Path (Join-Path -Path $repoRoot -ChildPath 'config\lab.psd1')
        $subnet = Get-LabIPv4Network -Address $config.Network.Prefix -PrefixLength $config.Network.PrefixLength
        $staticVms = @($config.VMs | Where-Object { Test-LabIPv4Address -Address $_.IPAddress })
    }
    It 'has a valid gateway inside the lab subnet' {
        Test-LabAddressInRange -Address $config.Network.Gateway -StartAddress $subnet.FirstHost -EndAddress $subnet.LastHost | Should -BeTrue
    }
    It 'keeps every static VM address inside the subnet' {
        foreach ($vm in $staticVms) {
            Test-LabAddressInRange -Address $vm.IPAddress -StartAddress $subnet.FirstHost -EndAddress $subnet.LastHost | Should -BeTrue -Because $vm.Name
        }
    }
    It 'never overlaps a static VM address with the DHCP range' {
        foreach ($vm in $staticVms) {
            Test-LabAddressInRange -Address $vm.IPAddress -StartAddress $config.Dhcp.StartRange -EndAddress $config.Dhcp.EndRange | Should -BeFalse -Because $vm.Name
        }
    }
    It 'uses unique VM names and IP addresses' {
        ($config.VMs.Name | Sort-Object -Unique).Count | Should -Be $config.VMs.Count
        ($staticVms.IPAddress | Sort-Object -Unique).Count | Should -Be $staticVms.Count
    }
    It 'defines exactly one domain controller' {
        @($config.VMs | Where-Object { $_.Role -eq 'DomainController' }).Count | Should -Be 1
    }
    It 'maps every share to a known department or ALL' {
        foreach ($share in $config.Shares) {
            ($config.Departments + 'ALL') | Should -Contain $share.Department
        }
    }
}

Describe 'User seed data (data/users.csv)' {
    BeforeAll {
        $users = Import-Csv -Path (Join-Path -Path $repoRoot -ChildPath 'data\users.csv') -Encoding UTF8
        $config = Get-LabConfig -Path (Join-Path -Path $repoRoot -ChildPath 'config\lab.psd1')
    }
    It 'has the expected columns' {
        $users[0].PSObject.Properties.Name | Should -Be @('GivenName', 'Surname', 'Department', 'Title')
    }
    It 'only uses departments defined in the lab configuration' {
        foreach ($user in $users) { $config.Departments | Should -Contain $user.Department }
    }
    It 'generates unique logon names' {
        $names = $users | ForEach-Object { ConvertTo-LabSamAccountName -GivenName $_.GivenName -Surname $_.Surname }
        ($names | Sort-Object -Unique).Count | Should -Be $users.Count
    }
}
