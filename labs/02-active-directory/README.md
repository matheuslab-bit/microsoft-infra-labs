# Lab 02 - Active Directory

Aqui o DC01 vira o primeiro controlador de domínio de `corp.lab.internal`, ganha uma estrutura de OUs e recebe os usuários a partir de uma planilha CSV.

É a parte que eu mais fazia na prática: no contact center, criar e organizar contas no AD era rotina diária. A ideia é fazer do jeito que eu gostaria de encontrar um AD organizado.

## Estrutura de OUs

```text
corp.lab.internal
└── CORP
    ├── Usuarios
    │   └── TI, Financeiro, Qualidade, Producao, RH
    ├── Computadores
    │   ├── Estacoes
    │   └── Servidores
    ├── Grupos
    │   ├── Seguranca   (GG_<departamento>)
    │   └── Recursos    (grupos de permissão das pastas, Lab 05)
    ├── Contas-de-Servico
    └── Desativados     (contas de quem saiu da empresa, Lab 09)
```

Usuários, computadores e grupos ficam em OUs separadas. Assim dá para aplicar uma GPO só nas estações, ou só num departamento, sem efeito colateral.

## Scripts

- `Install-LabForest.ps1 -Phase Prepare`: define o IP fixo, aponta o DNS para o próprio servidor e renomeia para DC01. Pede reinício.
- `Install-LabForest.ps1 -Phase Promote`: instala o AD DS e cria a floresta. A senha do modo de restauração (DSRM) é digitada na hora e não fica salva em lugar nenhum.
- `New-LabOUStructure.ps1`: cria as OUs com proteção contra exclusão acidental.
- `Import-LabUsers.ps1`: lê o [`users.csv`](../../data/users.csv), cria os grupos `GG_<departamento>`, cria cada usuário na OU do departamento e gera um CSV com tudo que foi criado.

## Detalhes que fazem diferença

- **Login no padrão `nome.sobrenome`, sem acento:** "João Conceição" vira `joao.conceicao`. O script respeita o limite de 20 caracteres do AD e, se o login já existir, acrescenta um número no final.
- **Senha inicial com troca obrigatória no primeiro logon:** a senha é digitada uma vez, na execução.
- **Domínio `.internal`:** é um sufixo reservado para redes privadas, então nunca vai conflitar com um domínio da internet.
- **Novos computadores vão para a OU Estacoes:** por padrão, o Windows coloca computadores novos no container "Computers", onde não dá para vincular GPO. O comando `redircmp` muda esse destino.

## Como rodar

```powershell
.\Install-LabForest.ps1 -Phase Prepare
# depois do reinício
.\Install-LabForest.ps1 -Phase Promote
# depois do reinício, já logado no domínio
.\New-LabOUStructure.ps1
.\Import-LabUsers.ps1 -WhatIf
.\Import-LabUsers.ps1
```

## Cuidados

- O DC precisa usar ele mesmo como DNS. Se a placa de rede apontar para o roteador ou para o 8.8.8.8, o logon e a entrada de máquinas no domínio falham.
- Antes de promover, confira o nome do servidor. Renomear um DC depois dá bem mais trabalho.

## Checklist

- [ ] `Get-ADDomain` responde e `dcdiag /q` não mostra erros
- [ ] `Get-ADOrganizationalUnit -Filter *` mostra a árvore acima
- [ ] Os 12 usuários estão nas OUs certas e nos grupos `GG_<departamento>`
- [ ] Logon no CL01 com um usuário novo pede a troca de senha
