# Lab 09 — Automação da operação

Transforma tarefas repetitivas do dia a dia em scripts padronizados, auditáveis e seguros de executar (todos aceitam `-WhatIf`).

## Scripts

| Script | Problema que resolve | Destaques |
| --- | --- | --- |
| `Get-LabADHealthReport.ps1` | Checagem diária manual do DC | Serviços críticos, replicação, disco, certificados vencendo, contas bloqueadas, senhas que nunca expiram e contas inativas. Gera relatório HTML com cores; código de saída 2 = crítico, 1 = alerta |
| `Invoke-LabUserOffboarding.ps1` | Desligamento de colaborador feito "na mão" e esquecido pela metade | Exporta os grupos antes de remover (auditoria), desativa, troca a senha por uma aleatória de 32 caracteres, tira de todos os grupos, registra o chamado na descrição e move para `Desativados` |
| `Get-LabStaleAccount.ps1` | Contas esquecidas são porta de entrada para ataques | Lista usuários e computadores inativos há mais de N dias, com carência para contas novas; com `-Disable`, desativa e move (revisar antes) |

## Exemplos

```powershell
# Relatório diário como tarefa agendada
.\Get-LabADHealthReport.ps1 -ReportPath \\FS01\TI$\relatorios\ad-health.html

# Desligamento com número do chamado (simulação primeiro)
.\Invoke-LabUserOffboarding.ps1 -SamAccountName diego.araujo -Ticket CHG-1042 -WhatIf
.\Invoke-LabUserOffboarding.ps1 -SamAccountName diego.araujo -Ticket CHG-1042

# Higiene de contas
.\Get-LabStaleAccount.ps1 -DaysInactive 90 | Export-Csv inativos.csv -NoTypeInformation
```

### Agendar o relatório diário

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\Labs\labs\09-operations-automation\Get-LabADHealthReport.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 7am
# No DC, a conta SYSTEM usa a conta de computador do DC, que tem leitura no AD; nenhuma senha fica salva
Register-ScheduledTask -TaskName 'AD Health Report' -Action $action -Trigger $trigger -User 'NT AUTHORITY\SYSTEM' -RunLevel Highest
```

## Validação

- [ ] Relatório HTML gerado no DC01, com status coloridos
- [ ] Desligamento de teste: conta desativada em `Desativados`, CSV de grupos salvo, log gravado
- [ ] `Get-LabStaleAccount.ps1 -Disable -WhatIf` lista as ações sem executá-las
