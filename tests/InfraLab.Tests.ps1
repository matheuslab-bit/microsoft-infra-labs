BeforeAll {
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\modules\InfraLab\InfraLab.psd1') -Force
}

Describe 'ConvertTo-LabSamAccountName' {
    It 'builds given.surname in lower case' {
        ConvertTo-LabSamAccountName -GivenName 'Ana' -Surname 'Ribeiro' | Should -Be 'ana.ribeiro'
    }
    It 'removes Portuguese diacritics' {
        $given = 'Jo' + [char]0x00E3 + 'o'                          # Joao with tilde
        $surname = 'Concei' + [char]0x00E7 + [char]0x00E3 + 'o'     # Conceicao with cedilla and tilde
        ConvertTo-LabSamAccountName -GivenName $given -Surname $surname | Should -Be 'joao.conceicao'
    }
    It 'uses the first given name and the last surname' {
        ConvertTo-LabSamAccountName -GivenName 'Maria Clara' -Surname 'Souza Lima' | Should -Be 'maria.lima'
    }
    It 'never exceeds the 20-character sAMAccountName limit' {
        $result = ConvertTo-LabSamAccountName -GivenName 'Maximiliano' -Surname 'Albuquerquerodrigues'
        $result.Length | Should -BeLessOrEqual 20
        $result | Should -Not -Match '\.$'
    }
}

Describe 'Test-LabIPv4Address' {
    It 'accepts <Address>' -ForEach @(@{ Address = '10.50.0.10' }, @{ Address = '192.168.1.1' }) {
        Test-LabIPv4Address -Address $Address | Should -BeTrue
    }
    It 'rejects <Address>' -ForEach @(@{ Address = 'DHCP' }, @{ Address = '10.50.0' }, @{ Address = '300.1.1.1' }, @{ Address = '' }) {
        Test-LabIPv4Address -Address $Address | Should -BeFalse
    }
}

Describe 'Get-LabIPv4Network' {
    It 'calculates a /24' {
        $net = Get-LabIPv4Network -Address '10.50.0.10' -PrefixLength 24
        $net.Network | Should -Be '10.50.0.0'
        $net.Broadcast | Should -Be '10.50.0.255'
        $net.SubnetMask | Should -Be '255.255.255.0'
        $net.FirstHost | Should -Be '10.50.0.1'
        $net.LastHost | Should -Be '10.50.0.254'
        $net.UsableHosts | Should -Be 254
    }
    It 'calculates a /26' {
        $net = Get-LabIPv4Network -Address '192.168.10.77' -PrefixLength 26
        $net.Network | Should -Be '192.168.10.64'
        $net.Broadcast | Should -Be '192.168.10.127'
        $net.SubnetMask | Should -Be '255.255.255.192'
        $net.UsableHosts | Should -Be 62
    }
}

Describe 'Test-LabAddressInRange' {
    It 'is true inside the range and on its edges' {
        Test-LabAddressInRange -Address '10.50.0.150' -StartAddress '10.50.0.100' -EndAddress '10.50.0.200' | Should -BeTrue
        Test-LabAddressInRange -Address '10.50.0.100' -StartAddress '10.50.0.100' -EndAddress '10.50.0.200' | Should -BeTrue
    }
    It 'is false outside the range' {
        Test-LabAddressInRange -Address '10.50.0.10' -StartAddress '10.50.0.100' -EndAddress '10.50.0.200' | Should -BeFalse
    }
}

Describe 'ConvertTo-LabDistinguishedName' {
    It 'converts an FQDN to DC components' {
        ConvertTo-LabDistinguishedName -DomainFqdn 'corp.lab.internal' | Should -Be 'DC=corp,DC=lab,DC=internal'
    }
}

Describe 'Get-LabConfig' {
    It 'throws when a required section is missing' {
        $path = Join-Path -Path $TestDrive -ChildPath 'broken.psd1'
        Set-Content -Path $path -Value "@{ Network = @{} }"
        { Get-LabConfig -Path $path } | Should -Throw "*missing*"
    }
    It 'throws when the file does not exist' {
        { Get-LabConfig -Path (Join-Path -Path $TestDrive -ChildPath 'nope.psd1') } | Should -Throw '*not found*'
    }
}
