# Microsoft Infra Labs

A small company's Microsoft environment, built from scratch on a Hyper-V lab and automated with PowerShell: domain, Group Policy, DNS, DHCP, file server, backup, monitoring and firewall.

[Português](README.md) | [English](README.en.md)

[![CI](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml)

## In 30 seconds

- **10 labs** that build a company's infrastructure step by step, each ending with a checklist that proves it works.
- **A toolkit** of the scripts I use on support tickets: network diagnostics, inventory, account lockout source.
- **Runbooks and checklists** written like a knowledge base: the problem, the order to investigate and the ready-to-run command.
- **Everything tested on every change** in GitHub Actions (lint and tests on Windows and Linux).

The write-ups are in Brazilian Portuguese; script help and code comments are in English.

## Labs

| # | Lab | What it solves |
| --- | --- | --- |
| 01 | [Hyper-V environment](labs/01-hyperv-environment/README.md) | Network and VMs created from one config file |
| 02 | [Active Directory](labs/02-active-directory/README.md) | Domain, OU structure and bulk user creation from CSV |
| 03 | [DNS and DHCP](labs/03-dns-dhcp/README.md) | Name resolution and automatic IP addressing |
| 04 | [Group Policy](labs/04-group-policy/README.md) | Password policy, stricter rule for IT, workstation baseline |
| 05 | [File server](labs/05-file-server/README.md) | Department shares with group-based access (AGDLP) |
| 06 | [Backup and recovery](labs/06-backup-recovery/README.md) | Backups with hash verification and restore testing |
| 07 | [Zabbix monitoring](labs/07-monitoring-zabbix/README.md) | AD, backup and server alerts, with an importable template |
| 08 | [FortiGate and VLANs](labs/08-fortigate-segmentation/README.md) | Network split into VLANs with access rules between them |
| 09 | [Day-to-day automation](labs/09-operations-automation/README.md) | AD health report, offboarding, stale accounts |
| 10 | [Grafana dashboards](labs/10-grafana-dashboards/README.md) | Infrastructure dashboard provisioned on startup |

**Status:** the scripts are done and pass CI. Running each lab on my Hyper-V host is in progress; a lab counts as done only when the checklist at the end of its README is complete.

## About me

I have worked in IT since 2014: Active Directory for a contact center with about 2,000 agent seats (Group Policy, Hyper-V, backup, FortiGate), network monitoring with Zabbix and PRTG, and today Tier 2 telecom and VoIP support. My cloud labs live in [google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio).

[LinkedIn](https://linkedin.com/in/matheus-s-ti) · [matheus.silva.gcp@gmail.com](mailto:matheus.silva.gcp@gmail.com)
