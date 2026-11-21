# Lab 05 - Servidor de arquivos com permissão por grupo

Pastas departamentais no FS01, com acesso controlado por grupos, e nunca por usuário direto na pasta.

## Como a permissão funciona (AGDLP)

Uso o modelo AGDLP, que é a recomendação da Microsoft para permissões no AD:

```text
ana.ribeiro (usuária)
  └── está no grupo GG_Financeiro              (quem a pessoa é: o departamento)
        └── que está no grupo DL_Share_Financeiro_M   (o que dá acesso: a pasta e o nível)
              └── que tem permissão de Modificar em D:\Shares\Financeiro
```

Na prática: quando alguém entra no Financeiro, basta colocar a pessoa no `GG_Financeiro`. Quando sai, tira do grupo. E para saber quem acessa uma pasta, basta olhar os grupos, sem caçar permissão espalhada usuário por usuário.

## O que o script faz (`New-LabFileShare.ps1`)

Para cada pasta definida na configuração:

1. Cria dois grupos de domínio local: `DL_Share_<pasta>_R` (leitura) e `DL_Share_<pasta>_M` (modificação).
2. Coloca o grupo do departamento dentro do grupo de modificação.
3. Cria a pasta, desliga a herança e deixa só: SYSTEM e Administrators com controle total, o grupo `_M` com modificar e o grupo `_R` com leitura.
4. Publica o compartilhamento com **enumeração baseada em acesso**: cada pessoa só enxerga as pastas que consegue abrir.

| Compartilhamento | Quem pode modificar |
| --- | --- |
| `\\FS01\Financeiro` | GG_Financeiro |
| `\\FS01\Qualidade` | GG_Qualidade |
| `\\FS01\Publico` | Domain Users (todos) |

No compartilhamento, deixo "Authenticated Users" com permissão de alterar. Quem manda de verdade é a permissão NTFS da pasta. Controlar nos dois lugares só complica o troubleshooting.

## Como rodar

No FS01, já no domínio:

```powershell
.\New-LabFileShare.ps1 -WhatIf
.\New-LabFileShare.ps1
```

## Cuidados

- O usuário só recebe um grupo novo depois de fazer logoff e logon de novo, porque o token de acesso é montado no logon.
- Nunca dar permissão direta a um usuário "só dessa vez". É assim que a bagunça de permissões começa.

## Checklist

- [ ] Um usuário do Financeiro grava em `\\FS01\Financeiro` e não vê a pasta Qualidade
- [ ] `Get-SmbShare | Select Name, FolderEnumerationMode` mostra `AccessBased`
- [ ] `(Get-Acl D:\Shares\Financeiro).Access` mostra só grupos, nenhum usuário
