# Lab 06 — Backup, restauração e recuperação do AD

Backup só vale se a restauração funciona. Este lab cobre as três camadas: arquivos, estado do sistema do DC e objetos do AD apagados por engano.

## Estratégia

| Camada | Ferramenta | Frequência sugerida | Restauração |
| --- | --- | --- | --- |
| Arquivos (`D:\Shares`) | Robocopy com ACLs + manifesto SHA256 | Diária | Copiar da pasta do dia; `Test-LabRestore.ps1` comprova a integridade |
| Estado do sistema do DC (NTDS, SYSVOL, registro) | `wbadmin start systemstatebackup` | Diária | Modo de restauração do AD (DSRM): não autoritativa ou autoritativa |
| Objetos do AD apagados | Lixeira do AD | Contínua | `Restore-ADObject`, online e com grupos preservados |
| GPOs | `Backup-LabGpo.ps1` (Lab 04) | Diária | `Restore-GPO` |

Retenção padrão: 14 dias (`config/lab.psd1`). Em produção vale a regra **3-2-1**: 3 cópias, 2 mídias, 1 fora do local.

## Scripts

| Script | O que faz |
| --- | --- |
| `Invoke-LabBackup.ps1` | Cópia versionada por data, preserva permissões NTFS, gera manifesto SHA256, faz o backup de estado do sistema (opcional) e apaga snapshots vencidos. Códigos de saída do Robocopy ≥ 8 interrompem como falha |
| `Test-LabRestore.ps1` | Restaura uma amostra aleatória do último snapshot e compara os hashes; retorna código 1 se algum arquivo falhar, para alimentar monitoramento ou tarefa agendada |
| `Enable-LabADRecycleBin.ps1 -RunDrill` | Habilita a Lixeira do AD e faz um simulado: cria, apaga e restaura um usuário de teste, verificando se o grupo foi preservado |

## Como executar

```powershell
.\Invoke-LabBackup.ps1 -WhatIf
.\Invoke-LabBackup.ps1 -IncludeSystemState -SystemStateTarget 'E:'
.\Test-LabRestore.ps1 -SampleSize 20 -ReportPath E:\Backups\logs\restore-test.csv
.\Enable-LabADRecycleBin.ps1 -RunDrill
```

## Validação

- [ ] Snapshot criado com `_manifest.csv` e permissões NTFS preservadas
- [ ] `Test-LabRestore.ps1` com 100% `PASS`
- [ ] Simulado da Lixeira do AD restaurou o usuário com o grupo `GG_TI`
- [ ] `wbadmin get versions` lista o backup de estado do sistema
