# Lab 04 — Group Policy (GPO) e políticas de senha

Padroniza a segurança das estações e das contas usando GPO e políticas de senha, com backup versionado das GPOs.

## O que é aplicado

**Política de senha do domínio** (`Set-ADDefaultDomainPasswordPolicy`)

| Item | Valor |
| --- | --- |
| Tamanho mínimo | 12 caracteres, com complexidade |
| Histórico | 24 senhas |
| Validade | 90 dias (mínimo de 1 dia) |
| Bloqueio | 5 tentativas → 15 minutos |

**Política refinada (PSO) para a equipe de TI** (`GG_TI`): 15 caracteres, validade de 60 dias, bloqueio após 3 tentativas por 30 minutos. Contas privilegiadas exigem mais do que contas comuns.

**GPO `LAB - Estacoes - Baseline`**, vinculada à OU `Computadores/Estacoes`:

| Configuração | Objetivo |
| --- | --- |
| Firewall do Windows ligado (domínio, privado, público) | Impede que um usuário desligue o firewall |
| SMBv1 desabilitado | Fecha o vetor usado pelo WannaCry |
| Gravação em armazenamento removível bloqueada | Prevenção de vazamento de dados (pen drive) |
| Bloqueio de tela com senha após 15 min | Estação desacompanhada não fica aberta |
| Ocultar último usuário no logon | Não entrega nomes de conta |

## Backup de GPO

`Backup-LabGpo.ps1` salva todas as GPOs numa pasta com data e hora, gera um relatório HTML de cada uma e apaga backups mais antigos que a retenção. Feito para rodar como tarefa agendada no DC.

```powershell
.\New-LabBaselineGpo.ps1 -WhatIf
.\New-LabBaselineGpo.ps1
.\Backup-LabGpo.ps1 -BackupRoot E:\Backups\GPO -RetentionDays 30

# Restaurar uma GPO alterada por engano
Restore-GPO -Name 'LAB - Estacoes - Baseline' -Path E:\Backups\GPO\<pasta>
```

## Validação

- [ ] No CL01: `gpupdate /force` e `gpresult /h relatorio.html` mostram a GPO aplicada
- [ ] Pen drive conectado abre somente para leitura
- [ ] `Get-ADUserResultantPasswordPolicy ana.ribeiro` retorna o PSO de TI
- [ ] Restauração de uma GPO a partir do backup testada
