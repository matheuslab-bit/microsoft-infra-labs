# Lab 04 - Group Policy e política de senha

GPO é o que mantém dezenas ou centenas de máquinas configuradas do mesmo jeito sem precisar passar em cada uma. Neste lab aplico uma política de senha para o domínio, uma regra mais rígida para a equipe de TI e um pacote básico de segurança para as estações.

## Política de senha do domínio

- Mínimo de 12 caracteres, com complexidade
- Não pode repetir as últimas 24 senhas
- Validade de 90 dias
- Conta bloqueada por 15 minutos depois de 5 tentativas erradas

## Regra mais rígida para a TI

Contas de administrador são as mais visadas. Por isso, o grupo `GG_TI` tem uma política de senha própria (Fine-Grained Password Policy): mínimo de 15 caracteres, validade de 60 dias e bloqueio de 30 minutos depois de 3 tentativas. Ela vale só para esse grupo e não muda nada para o resto da empresa.

## GPO das estações (`LAB - Estacoes - Baseline`)

Vinculada à OU `Computadores/Estacoes`:

- **Firewall do Windows sempre ligado**, nos três perfis. O usuário não consegue desligar.
- **SMBv1 desabilitado.** Protocolo antigo, usado pelo WannaCry.
- **Pen drive só para leitura.** Evita que arquivos da empresa saiam num pen drive.
- **Tela bloqueada depois de 15 minutos parada**, pedindo senha para voltar.
- **A tela de logon não mostra o último usuário**, para não entregar nomes de conta de graça.

## Backup das GPOs

`Backup-LabGpo.ps1` salva todas as GPOs numa pasta com data e hora e gera um relatório HTML de cada uma. Também apaga os backups mais antigos que a retenção (30 dias por padrão). A ideia é deixar como tarefa agendada no DC: se alguém alterar uma GPO por engano, dá para comparar com o relatório e restaurar.

## Como rodar

```powershell
.\New-LabBaselineGpo.ps1 -WhatIf
.\New-LabBaselineGpo.ps1
.\Backup-LabGpo.ps1 -BackupRoot E:\Backups\GPO -RetentionDays 30

# restaurar uma GPO a partir do backup
Restore-GPO -Name 'LAB - Estacoes - Baseline' -Path E:\Backups\GPO\<pasta-do-backup>
```

## Cuidados

- Política de senha do domínio só funciona na Default Domain Policy, ou seja, no nível do domínio. GPO de senha vinculada a uma OU não tem efeito nas contas do domínio. Por isso, para a TI, usei Fine-Grained Password Policy.
- Depois de mudar uma GPO, `gpupdate /force` na estação aplica na hora. Sem isso, pode levar até cerca de 90 minutos.

## Checklist

- [ ] No CL01, `gpresult /h relatorio.html` mostra a GPO aplicada
- [ ] Pen drive conectado abre só para leitura
- [ ] `Get-ADUserResultantPasswordPolicy ana.ribeiro` mostra a política da TI
- [ ] Restaurar uma GPO a partir do backup
