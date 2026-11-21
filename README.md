# Microsoft Infra Labs

Laboratório onde eu monto, do zero, o ambiente Microsoft de uma empresa: domínio, GPO, DNS, DHCP, servidor de arquivos, backup, monitoramento e firewall. Tudo roda no Hyper-V do meu PC e é automatizado com PowerShell.

[Português](README.md) | [English](README.en.md)

[![PowerShell CI](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml)

## Por que este repositório existe

Trabalho com infraestrutura desde 2014. Já administrei o Active Directory de um contact center grande, com GPO, Hyper-V, rotina de backup e FortiGate, e usei Zabbix e PRTG no monitoramento de clientes corporativos.

Aqui eu reproduzo esse tipo de ambiente em casa, de um jeito documentado e repetível. Serve para três coisas: praticar, testar mudanças sem risco e mostrar como eu organizo o trabalho.

O meu portfólio de nuvem fica em outro repositório: [google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio).

## O ambiente

São quatro VMs numa rede isolada (`10.50.0.0/24`), com saída para a internet por NAT no host:

```text
Host (Windows 11 Pro + Hyper-V)
 └── switch interno "LabInternal" + NAT
      ├── DC01   10.50.0.10   controlador de domínio, DNS e DHCP
      ├── FS01   10.50.0.20   servidor de arquivos e backup
      ├── MON01  10.50.0.30   Zabbix (Ubuntu + Docker)
      └── CL01   DHCP         estação Windows 11
```

Domínio: `corp.lab.internal`. Os usuários são fictícios e estão em [`data/users.csv`](data/users.csv).

## Os labs

1. [Ambiente Hyper-V](labs/01-hyperv-environment/README.md): rede isolada e criação das VMs a partir de um arquivo de configuração.
2. [Active Directory](labs/02-active-directory/README.md): promoção do DC, estrutura de OUs e criação de usuários em massa por CSV.
3. [DNS e DHCP](labs/03-dns-dhcp/README.md): zona reversa, encaminhadores, limpeza de registros antigos e escopo DHCP.
4. [Group Policy](labs/04-group-policy/README.md): política de senha, regra mais rígida para a TI, segurança básica das estações e backup das GPOs.
5. [Servidor de arquivos](labs/05-file-server/README.md): pastas por departamento com permissão por grupo (AGDLP).
6. [Backup e recuperação](labs/06-backup-recovery/README.md): backup com conferência de integridade, teste de restauração e Lixeira do AD.
7. [Monitoramento com Zabbix](labs/07-monitoring-zabbix/README.md): Zabbix em Docker e itens próprios para AD e backup.
8. [FortiGate e VLANs](labs/08-fortigate-segmentation/README.md): rede separada em VLANs, com regras de acesso entre elas.
9. [Automação do dia a dia](labs/09-operations-automation/README.md): relatório de saúde do AD, desligamento de colaborador e contas inativas.

## Como os scripts estão organizados

- **Uma configuração só.** IPs, nomes de VM, domínio, OUs, escopo DHCP e pastas ficam em [`config/lab.psd1`](config/lab.psd1). Para mudar o IP do DC, por exemplo, altero um único lugar.
- **Pode rodar de novo.** Cada script confere o que já existe e só cria o que falta.
- **Simulação antes.** Todo script que altera algo aceita `-WhatIf`, que mostra o que seria feito sem fazer.
- **Sem senha no código.** As senhas são pedidas na hora da execução, e o `.env` do Zabbix fica fora do Git.
- **Funções em comum.** Log, leitura da configuração, montagem de login e cálculo de IP ficam no módulo [`modules/InfraLab`](modules/InfraLab).
- Os scripts funcionam no Windows PowerShell 5.1, que é o padrão do Windows Server, e no PowerShell 7.

## Testes

A cada push, o GitHub Actions roda:

- o PSScriptAnalyzer, que é o lint do PowerShell;
- os testes com Pester, no Ubuntu e no Windows. Eles conferem as funções do módulo, a sintaxe e a ajuda de cada script, o suporte a `-WhatIf` e a consistência da configuração (por exemplo, o escopo DHCP não pode pegar o IP fixo de um servidor);
- a validação do `docker-compose` do Zabbix.

Para rodar na sua máquina:

```powershell
Install-Module Pester -RequiredVersion 6.2.0 -Scope CurrentUser -SkipPublisherCheck
Install-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope CurrentUser
Invoke-Pester ./tests
Invoke-ScriptAnalyzer -Path ./labs -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
```

## Situação atual

Os scripts passam no CI. O próximo passo é executar cada lab no meu Hyper-V e marcar o checklist que fica no fim de cada README. O que vem depois está no [ROADMAP](ROADMAP.md).

## Contato

[LinkedIn](https://linkedin.com/in/matheus-s-ti) · [GitHub](https://github.com/matheuslab-bit)

---

Ambiente de laboratório com dados fictícios. Antes de usar algum script num ambiente real, rode com `-WhatIf` e revise.
