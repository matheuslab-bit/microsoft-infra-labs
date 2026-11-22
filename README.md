# Microsoft Infra Labs

Meu portfólio de infraestrutura. Aqui eu monto, do zero, o ambiente Microsoft de uma empresa (domínio, GPO, DNS, DHCP, servidor de arquivos, backup, monitoramento e firewall), guardo os scripts que uso no dia a dia e escrevo os guias de troubleshooting que gostaria de encontrar numa base de conhecimento.

[Português](README.md) | [English](README.en.md)

[![CI](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml)

## Por que este repositório existe

Trabalho com infraestrutura desde 2014. Já administrei o Active Directory de um contact center com cerca de 2.000 posições de atendimento, com GPO, Hyper-V, rotina de backup e FortiGate. Monitorei a rede de clientes corporativos com Zabbix e PRTG, e hoje atuo como N2 em telecom e VoIP, acompanhando os serviços no Grafana e automatizando tarefas da equipe com JavaScript.

Este repositório junta essas frentes num lugar só, de um jeito documentado e repetível. Serve para praticar, testar mudanças sem risco e mostrar como eu organizo o trabalho.

O meu portfólio de nuvem fica em outro repositório: [google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio).

## O que tem aqui

```text
labs/          10 labs que montam o ambiente de uma empresa no Hyper-V
toolkit/       scripts do dia a dia: .bat, PowerShell e Linux
automacao-js/  automações em JavaScript (Node.js), com testes
docs/          runbooks de troubleshooting e checklists
```

## Labs

O ambiente tem quatro VMs numa rede isolada (`10.50.0.0/24`), com saída para a internet por NAT no host:

```text
Host (Windows 11 Pro + Hyper-V)
 └── switch interno "LabInternal" + NAT
      ├── DC01   10.50.0.10   controlador de domínio, DNS e DHCP
      ├── FS01   10.50.0.20   servidor de arquivos e backup
      ├── MON01  10.50.0.30   Zabbix e Grafana (Ubuntu + Docker)
      └── CL01   DHCP         estação Windows 11
```

1. [Ambiente Hyper-V](labs/01-hyperv-environment/README.md): rede isolada e criação das VMs a partir de um arquivo de configuração.
2. [Active Directory](labs/02-active-directory/README.md): promoção do DC, estrutura de OUs e criação de usuários em massa por CSV.
3. [DNS e DHCP](labs/03-dns-dhcp/README.md): zona reversa, encaminhadores, limpeza de registros antigos e escopo DHCP.
4. [Group Policy](labs/04-group-policy/README.md): política de senha, regra mais rígida para a TI, segurança básica das estações e backup das GPOs.
5. [Servidor de arquivos](labs/05-file-server/README.md): pastas por departamento com permissão por grupo (AGDLP).
6. [Backup e recuperação](labs/06-backup-recovery/README.md): backup com conferência de integridade, teste de restauração e Lixeira do AD.
7. [Monitoramento com Zabbix](labs/07-monitoring-zabbix/README.md): Zabbix em Docker, itens próprios para AD e backup e um template pronto para importar.
8. [FortiGate e VLANs](labs/08-fortigate-segmentation/README.md): rede separada em VLANs, com regras de acesso entre elas.
9. [Automação do dia a dia](labs/09-operations-automation/README.md): relatório de saúde do AD, desligamento de colaborador e contas inativas.
10. [Dashboards no Grafana](labs/10-grafana-dashboards/README.md): Grafana lendo o Zabbix, com um painel de infraestrutura que sobe já configurado.

## Caixa de ferramentas

Scripts que funcionam em qualquer máquina, para o atendimento do dia a dia. [Ver todos](toolkit/README.md).

- `coleta-info.bat`: um relatório completo da máquina num `.txt` para anexar ao chamado
- `diagnostico-rede.bat`: o roteiro de "estou sem internet" em 7 etapas, com `[OK]` ou `[FALHA]`
- `reparo-rede.bat` e `limpeza-disco.bat`: os reparos que mais resolvem, com confirmação antes
- `Test-Portas.ps1`: "é o firewall?", com listas prontas para AD, web, RDP, SQL e VoIP
- `Get-InventarioRemoto.ps1`: inventário de várias máquinas em CSV
- `Get-OrigemBloqueio.ps1`: qual computador está bloqueando a conta do usuário
- `Get-HistoricoReinicio.ps1` e `Export-MembrosGrupo.ps1`: quem reiniciou o servidor e revisão de acessos
- `coleta-info.sh`: a versão Linux do relatório da máquina

## Automação com JavaScript

Três automações em Node.js, sem dependências. [Ver detalhes](automacao-js/README.md).

- `relatorio-chamados.js`: transforma a exportação de chamados em relatório de SLA e tempo médio de resolução
- `verificar-certificados.js`: avisa quantos dias faltam para cada certificado TLS vencer
- `monitor-servicos.js`: confere se os serviços web respondem e em quanto tempo

## Guias do dia a dia

[Runbooks e checklists](docs/README.md) escritos do jeito que eu gostaria de encontrar numa base de conhecimento:

- Conta bloqueando toda hora, estação sem rede, voz ruim no VoIP, disco cheio e falha de replicação do AD
- Entrada e saída de colaborador, servidor novo antes de ir para produção, mudança planejada e TI de uma filial nova
- Rastreabilidade para auditoria (quem fez o quê, e quando) e separação da rede do escritório e da rede de automação

## Como o código está organizado

- **Uma configuração só.** IPs, nomes de VM, domínio, OUs, escopo DHCP e pastas ficam em [`config/lab.psd1`](config/lab.psd1).
- **Pode rodar de novo.** Cada script confere o que já existe e só cria o que falta.
- **Simulação antes.** Todo script que altera algo aceita `-WhatIf`.
- **Sem senha no código.** As senhas são pedidas na hora, e os `.env` ficam fora do Git.
- **Funciona no Windows Server padrão.** Os scripts rodam no Windows PowerShell 5.1 e no PowerShell 7.

## Testes

A cada push, o GitHub Actions roda:

- PSScriptAnalyzer (lint do PowerShell) nos labs, no módulo e na caixa de ferramentas;
- testes com Pester no Ubuntu e no Windows: funções do módulo, sintaxe e ajuda de cada script, suporte a `-WhatIf`, consistência da configuração e validade do painel do Grafana;
- testes das automações em JavaScript (`node --test`);
- ShellCheck no script Linux;
- validação dos `docker-compose` do Zabbix e do Grafana.

## Situação atual

Os scripts passam no CI, e as ferramentas da caixa de ferramentas já foram testadas num Windows 11. O próximo passo é executar cada lab no meu Hyper-V e marcar o checklist que fica no fim de cada README. O que vem depois está no [ROADMAP](ROADMAP.md).

## Contato

[LinkedIn](https://linkedin.com/in/matheus-s-ti) · [GitHub](https://github.com/matheuslab-bit) · [matheus.silva.gcp@gmail.com](mailto:matheus.silva.gcp@gmail.com)

---

Ambiente de laboratório com dados fictícios. Antes de usar algum script num ambiente real, rode com `-WhatIf` e revise.
