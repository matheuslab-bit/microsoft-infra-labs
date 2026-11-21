# Lab 02 — Active Directory Domain Services

Cria a floresta `corp.lab.internal`, uma estrutura de OUs pensada para GPO e a carga de usuários em massa, com auditoria.

## Objetivo

- Promover o **DC01** a primeiro controlador de domínio, com DNS integrado ao AD.
- Montar uma **estrutura de OUs em camadas**: usuários, computadores e grupos nunca se misturam.
- Criar usuários a partir de CSV, seguindo **AGDLP** (contas → grupos globais → grupos de domínio local → permissão).

## Estrutura de OUs

```text
corp.lab.internal
└── CORP
    ├── Usuarios
    │   ├── TI · Financeiro · Qualidade · Producao · RH
    ├── Computadores
    │   ├── Estacoes      ← destino padrão de novos computadores (redircmp)
    │   └── Servidores
    ├── Grupos
    │   ├── Seguranca     ← GG_<Departamento>
    │   └── Recursos      ← DL_<Recurso>_<R|M> (Lab 05)
    ├── Contas-de-Servico
    └── Desativados       ← contas desligadas (Lab 09)
```

## Scripts

| Script | O que faz |
| --- | --- |
| `Install-LabForest.ps1 -Phase Prepare` | IP estático, DNS em loopback e renomeia para DC01 |
| `Install-LabForest.ps1 -Phase Promote` | Instala o AD DS e cria a floresta; a senha DSRM é pedida de forma segura e nunca gravada |
| `New-LabOUStructure.ps1` | Cria as OUs protegidas contra exclusão acidental e redireciona o container padrão de computadores |
| `Import-LabUsers.ps1` | Cria grupos `GG_<Depto>` e usuários `nome.sobrenome` sem acento; senha inicial com troca obrigatória; gera relatório CSV |

## Decisões técnicas

- **Domínio `.internal`:** sufixo reservado para uso privado, então não colide com um domínio público.
- **`redircmp`:** computadores novos caem numa OU com GPO aplicada, em vez do container `Computers`, onde GPO não se aplica.
- **Nomes de login:** acentos removidos por normalização Unicode e limite de 20 caracteres do `sAMAccountName`; colisões ganham sufixo numérico.
- **Todos os scripts que alteram o ambiente aceitam `-WhatIf`.**

## Validação

- [ ] `Get-ADDomain`, `dcdiag /q` sem erros
- [ ] `Get-ADOrganizationalUnit -Filter *` mostra a árvore acima
- [ ] 12 usuários criados nas OUs corretas, membros de `GG_<Depto>`
- [ ] Login no CL01 com um usuário novo pedindo troca de senha
