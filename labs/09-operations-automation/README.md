# Lab 09 - Automação do dia a dia

Scripts para tarefas que se repetem toda semana e que, feitas à mão, acabam esquecidas ou feitas pela metade. Todos aceitam `-WhatIf`.

## Relatório de saúde do AD (`Get-LabADHealthReport.ps1`)

Uma checagem diária do DC que gera um relatório HTML colorido (verde, amarelo e vermelho):

- serviços essenciais rodando (NTDS, DNS, Netlogon, KDC, W32Time, DFSR);
- replicação do AD sem falhas;
- espaço livre em disco;
- certificados vencendo nos próximos 30 dias;
- contas bloqueadas, contas com senha que nunca expira e usuários sem logon há mais de 90 dias.

O script termina com código 2 se algo estiver crítico e 1 se houver alerta. Assim, dá para usar numa tarefa agendada ou plugar no Zabbix.

## Desligamento de colaborador (`Invoke-LabUserOffboarding.ps1`)

Quando alguém sai da empresa, o script faz tudo na ordem certa:

1. Salva num CSV os grupos que a pessoa tinha, para auditoria ou para devolver o acesso se foi engano.
2. Desativa a conta.
3. Troca a senha por uma aleatória, que ninguém conhece.
4. Remove a conta de todos os grupos.
5. Anota na descrição da conta a data e o número do chamado.
6. Move a conta para a OU `Desativados`.

O número do chamado é obrigatório (formato `CHG-1042`), para tudo ficar rastreável.

## Contas inativas (`Get-LabStaleAccount.ps1`)

Lista usuários e computadores sem logon há mais de N dias (90 por padrão). Conta criada há pouco tempo e que ainda não fez logon fica de fora. Com `-Disable`, desativa as contas e move para `Desativados`, mas a ideia é sempre revisar a lista antes.

Conta esquecida é uma porta de entrada comum em ataques, e limpar isso de tempos em tempos é uma higiene básica do AD.

## Exemplos

```powershell
# relatório diário
.\Get-LabADHealthReport.ps1 -ReportPath \\FS01\TI$\relatorios\saude-ad.html

# desligamento: simula primeiro, depois executa
.\Invoke-LabUserOffboarding.ps1 -SamAccountName diego.araujo -Ticket CHG-1042 -WhatIf
.\Invoke-LabUserOffboarding.ps1 -SamAccountName diego.araujo -Ticket CHG-1042

# contas inativas
.\Get-LabStaleAccount.ps1 -DaysInactive 90 | Export-Csv inativos.csv -NoTypeInformation
```

### Agendar o relatório

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Labs\labs\09-operations-automation\Get-LabADHealthReport.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 7am
# no DC, a conta SYSTEM consegue ler o AD, então não precisa salvar senha de nenhuma conta
Register-ScheduledTask -TaskName 'Relatorio de saude do AD' -Action $action -Trigger $trigger -User 'NT AUTHORITY\SYSTEM' -RunLevel Highest
```

## Checklist

- [ ] O relatório HTML é gerado no DC01 com as cores certas
- [ ] Desligamento de teste: conta em `Desativados`, CSV de grupos salvo e log gravado
- [ ] `Get-LabStaleAccount.ps1 -Disable -WhatIf` mostra o que faria, sem alterar nada
