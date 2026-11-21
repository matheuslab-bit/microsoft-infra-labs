# Lab 05 — Servidor de arquivos com permissões AGDLP

Publica pastas departamentais no **FS01** com permissões controladas por grupos, do jeito que um auditor espera ver.

## Modelo AGDLP

```text
Conta (ana.ribeiro)
  └─ Global:        GG_Financeiro           ← "quem a pessoa é" (departamento)
       └─ Domain Local: DL_Share_Financeiro_M ← "o que dá acesso" (recurso + nível)
            └─ Permissão NTFS: Modify em D:\Shares\Financeiro
```

Para dar ou tirar acesso, basta mudar a pessoa de grupo. Ninguém recebe permissão direta na pasta, então a auditoria de "quem acessa o quê" se resume a ler grupos.

## Permissões aplicadas

| Camada | Configuração |
| --- | --- |
| Compartilhamento (SMB) | `Authenticated Users`: alterar · `Administrators`: total |
| NTFS (o controle real) | Herança desativada · `SYSTEM` e `Administrators`: total · `DL_..._M`: modificar · `DL_..._R`: leitura |
| Enumeração baseada em acesso | O usuário só enxerga as pastas que consegue abrir |
| Cache offline | Desativado em pastas departamentais |

| Compartilhamento | Grupo com modificação |
| --- | --- |
| `\\FS01\Financeiro` | `GG_Financeiro` |
| `\\FS01\Qualidade` | `GG_Qualidade` |
| `\\FS01\Publico` | `Domain Users` |

## Como executar (no FS01, ingressado no domínio)

```powershell
.\New-LabFileShare.ps1 -WhatIf
.\New-LabFileShare.ps1
```

## Validação

- [ ] Usuário do Financeiro grava em `\\FS01\Financeiro` e **não vê** `\\FS01\Qualidade`
- [ ] `Get-SmbShare | Select Name, FolderEnumerationMode` mostra `AccessBased`
- [ ] `(Get-Acl D:\Shares\Financeiro).Access` lista só grupos, sem usuários diretos
