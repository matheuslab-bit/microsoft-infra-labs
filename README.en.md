# Microsoft Infra Labs

My infrastructure portfolio. Here I build a company's Microsoft environment from scratch (domain, Group Policy, DNS, DHCP, file server, backup, monitoring and firewall), keep the scripts I use day to day and write the troubleshooting guides I would like to find in a knowledge base.

[Português](README.md) | [English](README.en.md)

[![CI](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml)

## Why this repository exists

I have worked in IT infrastructure since 2014. I managed Active Directory for a contact center with about 2,000 agent seats, along with Group Policy, Hyper-V, backups and FortiGate. I monitored business customers' networks with Zabbix and PRTG, and today I am a Tier 2 analyst for telecom and VoIP, following our services on Grafana and automating team tasks with JavaScript.

This repository brings all of that together, documented and repeatable. The lab write-ups are in Brazilian Portuguese; script help and code comments are in English.

My cloud work lives in a separate repository: [google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio).

## What is inside

```text
labs/          10 labs that build a company environment on Hyper-V
toolkit/       day-to-day scripts: .bat, PowerShell and Linux
automacao-js/  JavaScript (Node.js) automations, with tests
docs/          troubleshooting runbooks and checklists
```

## Labs

1. [Hyper-V environment](labs/01-hyperv-environment/README.md): isolated network and VMs created from one config file.
2. [Active Directory](labs/02-active-directory/README.md): DC promotion, OU structure, bulk user creation from CSV.
3. [DNS and DHCP](labs/03-dns-dhcp/README.md): reverse zone, forwarders, scavenging, DHCP scope.
4. [Group Policy](labs/04-group-policy/README.md): password policy, stricter rule for IT, workstation baseline, GPO backups.
5. [File server](labs/05-file-server/README.md): department shares with group-based permissions (AGDLP).
6. [Backup and recovery](labs/06-backup-recovery/README.md): backups with integrity check, restore testing, AD Recycle Bin.
7. [Zabbix monitoring](labs/07-monitoring-zabbix/README.md): Zabbix on Docker, custom AD and backup items, an importable template.
8. [FortiGate and VLANs](labs/08-fortigate-segmentation/README.md): network split into VLANs with access rules between them.
9. [Day-to-day automation](labs/09-operations-automation/README.md): AD health report, employee offboarding, stale accounts.
10. [Grafana dashboards](labs/10-grafana-dashboards/README.md): Grafana reading Zabbix, with an infrastructure dashboard provisioned on startup.

## Toolkit

Scripts that work on any machine. [See all](toolkit/README.md). Highlights: a full machine report to attach to a ticket (`coleta-info.bat`), a 7-step "no internet" diagnostic (`diagnostico-rede.bat`), a port tester with presets for AD, web, RDP, SQL and VoIP (`Test-Portas.ps1`), remote inventory to CSV, finding the source of account lockouts, reboot history and group membership reviews.

## JavaScript automation

Three dependency-free Node.js tools ([details](automacao-js/README.md)): a ticket report with SLA and mean time to resolve, a TLS certificate expiry checker, and a web service health monitor with JSON output for Zabbix or Grafana.

## Runbooks and checklists

[Troubleshooting guides](docs/README.md) for account lockouts, workstations without network, VoIP voice quality, full disks and AD replication failures, plus checklists for onboarding, offboarding, new servers, planned changes and IT for a new branch site. Two guides cover audit traceability (who did what, and when) and separating office IT from operational technology (OT) networks.

## Tests

GitHub Actions runs PSScriptAnalyzer, Pester on Ubuntu and Windows, `node --test` for the JavaScript tools, ShellCheck for the Linux script, and `docker compose config` for Zabbix and Grafana on every push.

## Current status

The scripts pass CI, and the toolkit has been tested on Windows 11. Next step: run each lab on my Hyper-V host and tick the checklist at the end of each lab README. See the [roadmap](ROADMAP.md).
