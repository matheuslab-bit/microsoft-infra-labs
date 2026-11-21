# Lab 01 — Ambiente Hyper-V

Monta o laboratório isolado em que todos os outros labs rodam, usando o Hyper-V do Windows 11 Pro.

## Objetivo

- Criar uma rede interna isolada (`10.50.0.0/24`) com NAT, para as VMs terem internet sem ficar expostas na rede física.
- Provisionar as VMs a partir de um arquivo de configuração único ([`config/lab.psd1`](../../config/lab.psd1)), como infraestrutura como código.

## Topologia

| VM | Função | IP | Recursos |
| --- | --- | --- | --- |
| DC01 | Controlador de domínio, DNS, DHCP | 10.50.0.10 | 2 vCPU · 4 GB · 60 GB |
| FS01 | Servidor de arquivos e backup | 10.50.0.20 | 2 vCPU · 4 GB · 80 GB |
| MON01 | Zabbix (Ubuntu + Docker) | 10.50.0.30 | 2 vCPU · 4 GB · 40 GB |
| CL01 | Estação Windows 11 | DHCP | 2 vCPU · 4 GB · 60 GB |

## Decisões técnicas

| Decisão | Motivo |
| --- | --- |
| Switch **Internal** + `New-NetNat` | Isola o lab da rede de casa ou da empresa e mantém acesso à internet para atualizações. |
| VMs **Geração 2** com Secure Boot | Firmware UEFI e proteção contra bootkits; o Linux usa o template *Microsoft UEFI CA*. |
| **vTPM** nas VMs Windows | Requisito do Windows 11 e base para BitLocker. |
| Checkpoints **Production** e automáticos desligados | Checkpoints consistentes via VSS, sem consumir disco a cada boot. |
| VHDX **dinâmico** | Economiza espaço no host de laboratório. |

## Como executar

```powershell
# PowerShell como Administrador, com o Hyper-V habilitado
.\New-LabNetwork.ps1 -WhatIf     # mostra o que seria feito
.\New-LabNetwork.ps1
.\New-LabVM.ps1 -Name DC01,FS01,CL01
```

ISOs de avaliação gratuitas: Windows Server 2022 Evaluation e Windows 11 Enterprise Evaluation (Microsoft Evaluation Center) e Ubuntu Server 24.04 LTS.

## Validação

- [ ] `Get-VMSwitch LabInternal` e `Get-NetNat LabNAT` retornam os objetos
- [ ] As VMs iniciam pelo DVD e recebem rede
- [ ] Checkpoint criado e revertido com sucesso em uma VM de teste
