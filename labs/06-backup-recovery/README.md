# Lab 06 - Backup e recuperação

> **Em poucas palavras:** Backup é a cópia de segurança. O teste de restauração é provar que essa cópia realmente volta quando alguém precisa dela.

**Situação:** scripts prontos e testados no CI. A execução no meu Hyper-V está em andamento, e o checklist no fim desta página mostra o que já foi conferido.

Backup que nunca foi restaurado é só uma suposição. Por isso este lab não para no backup: ele também testa a restauração.

## O que entra no backup

| O quê | Como | Como volto |
| --- | --- | --- |
| Arquivos das pastas (`D:\Shares`) | Robocopy, guardando as permissões, numa pasta por data | Copio de volta da pasta do dia |
| Estado do sistema do DC (banco do AD, SYSVOL, registro) | `wbadmin` | Modo de restauração do AD (DSRM) |
| Usuário ou grupo apagado por engano | Lixeira do AD | `Restore-ADObject`, sem precisar de backup |
| GPOs | `Backup-LabGpo.ps1` (Lab 04) | `Restore-GPO` |

A retenção padrão é de 14 dias e pode ser alterada em `config/lab.psd1`. Num ambiente de produção eu seguiria a regra 3-2-1: três cópias, em dois tipos de mídia, sendo uma fora da empresa.

## Scripts

**`Invoke-LabBackup.ps1`** copia as pastas para `E:\Backups\files\<data_hora>` mantendo as permissões NTFS. Para cada cópia, gera um arquivo `_manifest.csv` com o hash SHA256 de cada arquivo. Com `-IncludeSystemState`, também faz o backup do estado do sistema do DC. No fim, apaga as cópias mais antigas que a retenção. Se o Robocopy retornar erro (código 8 ou maior), o script para e registra no log.

**`Test-LabRestore.ps1`** pega a cópia mais recente, restaura uma amostra aleatória de arquivos numa pasta temporária e compara o hash de cada um com o manifesto. Se algum não bater, o script termina com código 1, o que permite usar o resultado numa tarefa agendada ou no monitoramento.

**`Enable-LabADRecycleBin.ps1`** habilita a Lixeira do AD. Com `-RunDrill`, faz um simulado: cria um usuário de teste, coloca num grupo, apaga, restaura e confere se ele voltou com o grupo.

## Como rodar

```powershell
.\Invoke-LabBackup.ps1 -WhatIf
.\Invoke-LabBackup.ps1 -IncludeSystemState -SystemStateTarget 'E:'
.\Test-LabRestore.ps1 -SampleSize 20 -ReportPath E:\Backups\logs\teste-restauracao.csv
.\Enable-LabADRecycleBin.ps1 -RunDrill
```

## Cuidados

- Habilitar a Lixeira do AD não tem volta. Num ambiente real, combine antes com o time.
- O backup de estado do sistema precisa de um volume próprio para destino; não dá para gravar no mesmo disco do sistema.
- Sem a Lixeira do AD, recuperar um usuário apagado exige restauração autoritativa a partir de backup, um processo bem mais demorado.

## Checklist

- [ ] A pasta da cópia tem o `_manifest.csv` e as permissões NTFS foram mantidas
- [ ] `Test-LabRestore.ps1` retorna tudo `PASS`
- [ ] O simulado da Lixeira do AD trouxe o usuário de volta com o grupo `GG_TI`
- [ ] `wbadmin get versions` lista o backup de estado do sistema
