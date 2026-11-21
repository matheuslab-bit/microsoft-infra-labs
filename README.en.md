# Microsoft Infrastructure Labs

**On-premises Microsoft infrastructure lab as code:** Windows Server, Active Directory, Group Policy, DNS/DHCP, file services, backup and restore testing, Zabbix monitoring and FortiGate network segmentation, all automated with PowerShell.

[Português](README.md) | [English](README.en.md)

[![PowerShell CI](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell&logoColor=white)
![Windows Server](https://img.shields.io/badge/Windows%20Server-2022-0078D4?logo=windows&logoColor=white)
![Zabbix](https://img.shields.io/badge/Zabbix-7.0%20LTS-D40000)

This repository rebuilds, in a Hyper-V home lab, the environment an infrastructure analyst runs day to day. Each lab has a goal, justified design decisions, idempotent scripts that support `-WhatIf`, and a validation checklist. Lab documentation is written in Brazilian Portuguese; code, comments and script help are in English.

> Google Cloud portfolio (Terraform, IAP, GCS): [matheuslab-bit/google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio)

## Labs

| # | Lab | What it demonstrates |
| --- | --- | --- |
| 01 | [Hyper-V environment](labs/01-hyperv-environment/README.md) | Isolated internal network with NAT; Gen 2 VMs with Secure Boot and vTPM built from one configuration file |
| 02 | [Active Directory](labs/02-active-directory/README.md) | New forest with integrated DNS, tiered OUs, CSV bulk user provisioning with AGDLP and an audit report |
| 03 | [DNS and DHCP](labs/03-dns-dhcp/README.md) | Reverse zone, forwarders, scavenging, authorized DHCP scope with pre-flight range validation |
| 04 | [Group Policy](labs/04-group-policy/README.md) | Password/lockout policy, fine-grained policy for admins, workstation security baseline, versioned GPO backups |
| 05 | [File server](labs/05-file-server/README.md) | Departmental shares, NTFS through AGDLP groups, access-based enumeration |
| 06 | [Backup and recovery](labs/06-backup-recovery/README.md) | Versioned backups with SHA256 manifest, **automated restore testing**, system state backup, AD Recycle Bin drill |
| 07 | [Zabbix monitoring](labs/07-monitoring-zabbix/README.md) | Zabbix 7.0 LTS on Docker, Agent 2 with custom items (AD replication, locked accounts, backup age) |
| 08 | [FortiGate and VLANs](labs/08-fortigate-segmentation/README.md) | Server/workstation/management VLANs, DHCP relay, least-privilege access matrix, implicit-deny logging |
| 09 | [Operations automation](labs/09-operations-automation/README.md) | Daily AD health report, standardized employee offboarding, stale account hygiene |

## Engineering practices

- **Configuration as code:** network, VMs, domain, OUs, DHCP, shares and backup come from [`config/lab.psd1`](config/lab.psd1).
- **Idempotent and safe:** every state-changing script supports `-WhatIf`/`-Confirm`, enforced by a test.
- **No secrets in code:** passwords are prompted as `SecureString`; `.env` is git-ignored; a test rejects hard-coded passwords.
- **Shared, unit-tested module:** [`modules/InfraLab`](modules/InfraLab) handles logging, configuration, logon names and IPv4 math.
- **CI:** PSScriptAnalyzer, Pester on Ubuntu and Windows, and `docker compose config` validation.
- **Compatibility:** ASCII-only scripts that run on Windows PowerShell 5.1 and PowerShell 7.

## Status

All labs are validated in CI (lint and tests). Execution in the Hyper-V lab is in progress; each lab README has its validation checklist. See the [roadmap](ROADMAP.md).

---

*Lab environment with fictitious data. Review scripts with `-WhatIf` before running them anywhere real.*
