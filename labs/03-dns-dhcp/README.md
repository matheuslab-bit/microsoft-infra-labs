# Lab 03 - DNS e DHCP

Com o domínio criado, faltam os dois serviços que fazem a rede funcionar sozinha: o DNS resolve os nomes e o DHCP entrega IP para as estações.

## DNS (`Set-LabDns.ps1`)

- **Encaminhadores** para `1.1.1.1` e `8.8.8.8`, para resolver nomes da internet.
- **Zona reversa** (`0.50.10.in-addr.arpa`) integrada ao AD. Ajuda muito no troubleshooting: dá para fazer `nslookup` pelo IP e ver o nome da máquina.
- **Limpeza de registros antigos** (aging e scavenging, 7 + 7 dias). Sem isso, o DNS acumula registros de máquinas que nem existem mais.
- **Registros fixos** (A e PTR) para DC01, FS01 e MON01, que têm IP estático.
- **Atualização dinâmica só segura:** apenas máquinas do domínio conseguem registrar nomes.

## DHCP (`Set-LabDhcp.ps1`)

- Escopo `LAB-Estacoes`, de `10.50.0.100` a `10.50.0.200`, com lease de 8 horas.
- Entrega gateway `10.50.0.1`, DNS `10.50.0.10` e o sufixo `corp.lab.internal`.
- O servidor é autorizado no AD. Isso impede que outro servidor DHCP qualquer comece a distribuir IP na rede.
- O próprio DHCP cria o registro DNS da estação e apaga quando o lease vence.

Antes de alterar qualquer coisa, o script confere se a faixa do escopo está dentro da sub-rede e se não pega o IP fixo de algum servidor. Se pegar, ele para e avisa. Essas contas de IP ficam no módulo `InfraLab` e têm testes automatizados.

## Como rodar

No DC01:

```powershell
.\Set-LabDns.ps1 -WhatIf
.\Set-LabDns.ps1
.\Set-LabDhcp.ps1
```

## Cuidados

- Se o servidor DHCP não estiver autorizado no AD, o serviço sobe, mas não entrega IP. É um erro clássico.
- Reserve os IPs fixos (servidores, impressoras) fora da faixa do escopo, ou crie exclusões.

## Checklist

- [ ] `nslookup fs01` e `nslookup 10.50.0.20` respondem pelo DC01
- [ ] O CL01 recebe IP entre `.100` e `.200` com DNS `10.50.0.10` (`ipconfig /all`)
- [ ] O registro do CL01 aparece na zona DNS depois que ele pega IP
