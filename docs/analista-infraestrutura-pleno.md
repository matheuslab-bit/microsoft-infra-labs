# Analista de Infraestrutura Pleno: o que a vaga pede e onde eu mostro

Juntei as responsabilidades que aparecem nas vagas de analista de infraestrutura pleno, com atenção ao caso de uma indústria farmacêutica que está abrindo uma fábrica nova. Para cada uma, aponto onde está a prova. O que eu ainda não pratiquei fica marcado como estudo, sem fingir que já fiz.

**Como ler a coluna "Situação":**

- **Experiência**: fiz no trabalho (resumo no [README](../README.md)).
- **Implantado**: lab executado de verdade, com o teste registrado no README do lab.
- **Lab escrito**: scripts e documentação prontos e passando no CI, mas ainda não executados no meu Hyper-V.
- **Estudado**: escrevi um guia ou um checklist sobre o assunto, mas ainda não pratiquei.

## O que muda do júnior para o pleno

O júnior atende chamados seguindo um roteiro. Do pleno se espera:

- resolver sozinho os problemas de N2 e N3, até a causa raiz;
- manter a base funcionando: servidores, rede, backup e monitoramento;
- planejar e executar mudanças com plano de volta;
- documentar o ambiente e os procedimentos;
- conduzir projetos de porte médio com apoio de um sênior ou do coordenador, como montar a TI de uma unidade nova;
- atender fornecedores e auditorias.

## Servidores e identidade

| Responsabilidade | Onde mostro | Situação |
| --- | --- | --- |
| Administrar Windows Server, Active Directory e GPO | AD de um contact center com cerca de 2.000 posições; [lab 02](../labs/02-active-directory/README.md) e [lab 04](../labs/04-group-policy/README.md) | Experiência e lab escrito |
| DNS e DHCP | [Lab 03](../labs/03-dns-dhcp/README.md) | Lab escrito |
| Virtualização | Hyper-V no trabalho; [lab 01](../labs/01-hyperv-environment/README.md) | Experiência e lab escrito. VMware: a estudar |
| Servidor de arquivos com permissão por grupo | [Lab 05](../labs/05-file-server/README.md) (AGDLP) | Lab escrito |
| Linux | VM Debian no [Google Cloud](https://github.com/matheuslab-bit/google-cloud-portfolio/tree/main/projects/02-secure-compute-engine); [`coleta-info.sh`](../toolkit/README.md) | Implantado |
| Microsoft 365, Entra ID e Intune | [ROADMAP](../ROADMAP.md) | A estudar |

## Redes e segurança

| Responsabilidade | Onde mostro | Situação |
| --- | --- | --- |
| Firewall, VLANs e VPN | FortiGate no trabalho; [lab 08](../labs/08-fortigate-segmentation/README.md) | Experiência e lab escrito |
| Ligar uma unidade nova à matriz (VPN ou SD-WAN, dois links) | [Checklist de unidade industrial nova](checklists/ti-unidade-industrial-nova.md) | Estudado |
| Separar a rede do escritório da rede da produção (TI e OT) | [Guia da indústria farmacêutica](guias/infra-industria-farmaceutica.md#rede-industrial-ti-e-ot); [lab 08](../labs/08-fortigate-segmentation/README.md) | Lab escrito e estudado |
| Acesso administrativo sem expor portas para a internet | VM sem IP público com acesso só pelo IAP e saída por Cloud NAT, no [Google Cloud](https://github.com/matheuslab-bit/google-cloud-portfolio) | Implantado |
| Telefonia VoIP | Analista N2 de telecom e VoIP hoje; [runbook de qualidade de voz](runbooks/voip-qualidade-de-voz.md) | Experiência |

## Backup, continuidade e monitoramento

| Responsabilidade | Onde mostro | Situação |
| --- | --- | --- |
| Rotina de backup com teste de restauração | Rotina de backup no trabalho; [lab 06](../labs/06-backup-recovery/README.md) com hash SHA-256 e teste de restauração | Experiência e lab escrito |
| Monitoramento e alertas | Zabbix, PRTG e Grafana no trabalho; [lab 07](../labs/07-monitoring-zabbix/README.md) e [lab 10](../labs/10-grafana-dashboards/README.md); alertas por e-mail testados no [Google Cloud](https://github.com/matheuslab-bit/google-cloud-portfolio/tree/main/projects/04-monitoring-alerts) | Experiência e implantado |
| Plano de recuperação de desastre | [Guia da indústria farmacêutica](guias/infra-industria-farmaceutica.md#backup-e-restauração) | Estudado |

## Processos e atendimento (ITIL)

| Responsabilidade | Onde mostro | Situação |
| --- | --- | --- |
| Chamados de N2 com análise de causa raiz | Cerca de 500 chamados por mês hoje | Experiência |
| Gestão de mudanças com plano de volta | [Checklist de mudança planejada](checklists/mudanca-planejada.md) | Estudado |
| Entrada e saída de colaborador e revisão de acessos | [Checklists](README.md#checklists); [lab 09](../labs/09-operations-automation/README.md); [`Export-MembrosGrupo.ps1`](../toolkit/powershell/Export-MembrosGrupo.ps1) | Lab escrito |
| Base de conhecimento | [Runbooks](README.md#runbooks-troubleshooting) | Feito |
| Relatório de SLA dos chamados | [`relatorio-chamados.js`](../automacao-js/README.md) | Feito, com testes no CI |

## Automação e nuvem

| Responsabilidade | Onde mostro | Situação |
| --- | --- | --- |
| Automação com PowerShell | Todo este repositório, com PSScriptAnalyzer e Pester no CI | Feito |
| Infraestrutura como código | Sete labs de Terraform no [Google Cloud](https://github.com/matheuslab-bit/google-cloud-portfolio), seis deles no ar | Implantado |
| CI/CD | GitHub Actions nos dois repositórios; acesso ao Google Cloud sem chave (Workload Identity Federation) | Implantado |
| Controle de custo em nuvem | Orçamento com alertas no [Google Cloud](https://github.com/matheuslab-bit/google-cloud-portfolio/tree/main/projects/04-monitoring-alerts) | Implantado |

## O que é específico de uma indústria farmacêutica

| Responsabilidade | Onde mostro | Situação |
| --- | --- | --- |
| Manter sistemas computadorizados sob controle (Anvisa RDC 658/2022 e IN 134/2022) | [Guia da indústria farmacêutica](guias/infra-industria-farmaceutica.md) | Estudado |
| Integridade de dados (ALCOA+): contas nominais, trilha de auditoria, horário sincronizado | [Guia, seção ALCOA+](guias/infra-industria-farmaceutica.md#integridade-de-dados-alcoa) | Estudado |
| Controle de mudanças GxP e qualificação de infraestrutura (IQ) | [Guia, seção de mudanças](guias/infra-industria-farmaceutica.md#controle-de-mudanças) | Estudado |
| Montar a TI de uma fábrica nova | [Checklist de unidade industrial nova](checklists/ti-unidade-industrial-nova.md) | Estudado |
| Suporte a ERP, MES, LIMS e aos equipamentos da produção | | A estudar |

## Próximos passos

O que estou estudando para fechar essas lacunas está no [ROADMAP](../ROADMAP.md), na seção "Indústria regulada".
