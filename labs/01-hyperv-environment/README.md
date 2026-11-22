# Lab 01 - Ambiente Hyper-V

> **Em poucas palavras:** É a sala de servidores dentro de um computador só. Um script cria a rede isolada e as quatro máquinas virtuais que todos os outros labs usam.

**Situação:** executado no meu Hyper-V em 22/11/2026. Rede, NAT, DC01 e FS01 criados, internet saindo pelo NAT e checkpoint revertido com sucesso ([relatório](evidencias/2026-11-22-test-labenvironment.txt)). O MON01 e o CL01 entram nos labs 07 e 03.

Este é o lab base: cria a rede isolada e as máquinas virtuais que todos os outros labs usam.

## O que os scripts fazem

`New-LabNetwork.ps1` cria um switch interno no Hyper-V, coloca o IP `10.50.0.1` no host (que vira o gateway das VMs) e configura um NAT. Com isso as VMs saem para a internet, mas ficam fora da minha rede de casa.

`New-LabVM.ps1` lê a lista de VMs em [`config/lab.psd1`](../../config/lab.psd1) e cria cada uma com o disco, a memória e a ISO certos. VM que já existe é ignorada.

| VM | Para que serve | IP | vCPU / RAM / disco |
| --- | --- | --- | --- |
| DC01 | Domínio, DNS e DHCP | 10.50.0.10 | 2 / 4 GB / 60 GB |
| FS01 | Arquivos e backup | 10.50.0.20 | 2 / 4 GB / 80 GB |
| MON01 | Zabbix e Grafana | 10.50.0.30 | 2 / 4 GB / 40 GB |
| CL01 | Estação de trabalho | DHCP | 2 / 4 GB / 60 GB |

## Por que fiz assim

- **Switch interno com NAT, e não externo:** o lab tem DHCP e DNS próprios. Num switch externo, o DHCP do lab poderia entregar IP para os aparelhos de casa.
- **VMs de geração 2 com Secure Boot:** é o padrão atual. Nas VMs Windows também adicionei TPM virtual, que o Windows 11 exige.
- **Checkpoints do tipo Production e sem checkpoint automático:** o checkpoint fica consistente (usa VSS) e não ocupa disco a cada vez que a VM liga.
- **Disco dinâmico:** num PC de casa, espaço em disco faz diferença.

## Como rodar

PowerShell como administrador, com o Hyper-V já habilitado:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force   # vale só para esta janela
.\New-LabNetwork.ps1 -WhatIf     # só mostra o que faria
.\New-LabNetwork.ps1
.\New-LabVM.ps1 -Name DC01,FS01 -WhatIf
.\New-LabVM.ps1 -Name DC01,FS01
```

As ISOs ficam em `C:\HyperV\ISO`. Uso as versões de avaliação gratuitas do Windows Server 2022 e do Windows 11 Enterprise, além do Ubuntu Server 24.04. Dá para criar as VMs aos poucos: o CL01 e o MON01 só entram nos labs que precisam deles.

## Como conferir

`Test-LabEnvironment.ps1` confere o ambiente e salva um relatório em `C:\HyperV\Lab\evidencia-lab01.txt`, com cada item marcado como `PASS`, `FAIL` ou `SKIP`:

```powershell
.\Test-LabEnvironment.ps1                                    # só o host: switch, NAT e VMs
$cred = Get-Credential Administrator
.\Test-LabEnvironment.ps1 -Credential $cred -IncludeCheckpointTest
```

- Com `-Credential`, ele entra na VM pelo **PowerShell Direct** (direto pelo Hyper-V, sem depender da rede) e testa a saída para a internet pelo NAT.
- Com `-IncludeCheckpointTest`, ele cria um checkpoint, grava um arquivo na VM, reverte o checkpoint e confere se o arquivo sumiu.

## Levando os scripts para dentro da VM

O PowerShell Direct também copia arquivos do host para a VM, sem pasta compartilhada e sem rede:

```powershell
$s = New-PSSession -VMName DC01 -Credential $cred
Copy-Item -ToSession $s -Path "$HOME\Documents\Projetos\microsoft-infra-labs" -Destination C:\Lab\microsoft-infra-labs -Recurse -Force
```

## Cuidados

- VM Linux com Secure Boot precisa do template "Microsoft UEFI Certificate Authority", senão não dá boot. O script já trata isso para a MON01.
- Se o NAT não funcionar, confira se não existe outro `NetNat` usando a mesma faixa: o Windows só aceita um NAT por faixa de IP.

## Checklist

- [x] `Get-VMSwitch LabInternal` e `Get-NetNat LabNAT` retornam o switch e o NAT, e DC01 e FS01 foram criadas como geração 2, com Secure Boot e TPM virtual (22/11/2026)
- [x] O DC01 deu boot pela ISO, o Windows Server 2022 foi instalado e a VM chegou a `1.1.1.1:443` pelo NAT (22/11/2026)
- [x] Checkpoint criado no DC01, arquivo gravado depois dele e revertido: o arquivo sumiu (22/11/2026)

## O que aprendi na execução

- **"Press any key to boot from CD or DVD" dura poucos segundos.** Se ninguém aperta uma tecla, a VM de geração 2 tenta o disco vazio e para em "No operating system was loaded". Basta reiniciar pela janela da VM e apertar uma tecla logo em seguida.
- **PowerShell Direct resolve a primeira configuração.** Com a VM ainda sem IP, `New-PSSession -VMName` e `Copy-Item -ToSession` levaram os scripts para dentro dela pelo próprio Hyper-V.
- **Checkpoint Production desliga a VM ao reverter.** Ele guarda um estado consistente (usa VSS), mas sem a memória. Por isso o script liga a VM de novo e espera ela responder antes de conferir.
