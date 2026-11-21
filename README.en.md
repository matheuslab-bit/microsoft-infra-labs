# Microsoft Infra Labs

A home lab where I build a company's Microsoft environment from scratch: domain, Group Policy, DNS, DHCP, file server, backup, monitoring and firewall. Everything runs on Hyper-V on my PC and is automated with PowerShell.

[Português](README.md) | [English](README.en.md)

[![PowerShell CI](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml/badge.svg)](https://github.com/matheuslab-bit/microsoft-infra-labs/actions/workflows/powershell-ci.yml)

## Why this repository exists

I have worked in IT infrastructure since 2014. I have managed Active Directory for a large contact center, including Group Policy, Hyper-V, backups and FortiGate, and I have used Zabbix and PRTG to monitor business customers.

This repository rebuilds that kind of environment at home, documented and repeatable, so I can practice, test changes safely and show how I work. The lab write-ups are in Brazilian Portuguese; script help and code comments are in English.

My cloud work lives in a separate repository: [google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio).

## The environment

Four VMs on an isolated network (`10.50.0.0/24`) with internet access through NAT on the host: DC01 (domain controller, DNS, DHCP), FS01 (file server and backup), MON01 (Zabbix on Ubuntu + Docker) and CL01 (Windows 11 client). Domain: `corp.lab.internal`. All users are fictitious.

## Labs

1. [Hyper-V environment](labs/01-hyperv-environment/README.md): isolated network and VMs created from one config file.
2. [Active Directory](labs/02-active-directory/README.md): DC promotion, OU structure, bulk user creation from CSV.
3. [DNS and DHCP](labs/03-dns-dhcp/README.md): reverse zone, forwarders, scavenging, DHCP scope.
4. [Group Policy](labs/04-group-policy/README.md): password policy, stricter rule for IT, workstation baseline, GPO backups.
5. [File server](labs/05-file-server/README.md): department shares with group-based permissions (AGDLP).
6. [Backup and recovery](labs/06-backup-recovery/README.md): backups with integrity check, restore testing, AD Recycle Bin.
7. [Zabbix monitoring](labs/07-monitoring-zabbix/README.md): Zabbix on Docker with custom AD and backup items.
8. [FortiGate and VLANs](labs/08-fortigate-segmentation/README.md): network split into VLANs with access rules between them.
9. [Day-to-day automation](labs/09-operations-automation/README.md): AD health report, employee offboarding, stale accounts.

## How the scripts work

- All settings live in [`config/lab.psd1`](config/lab.psd1).
- Scripts can run more than once; they only create what is missing.
- Every script that changes something supports `-WhatIf`.
- No passwords in code: they are prompted at run time.
- Shared functions live in [`modules/InfraLab`](modules/InfraLab).
- They run on Windows PowerShell 5.1 and PowerShell 7.

GitHub Actions runs PSScriptAnalyzer, Pester tests on Ubuntu and Windows, and a `docker compose config` check on every push.

## Current status

The scripts pass CI. Next step: run each lab on my Hyper-V host and tick the checklist at the end of each lab README. See the [roadmap](ROADMAP.md).
