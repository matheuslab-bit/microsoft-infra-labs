# Lab 03 — DNS e DHCP

Completa os serviços de rede do domínio: resolução de nomes interna e externa e distribuição automática de IP às estações.

## DNS

| Configuração | Valor | Por quê |
| --- | --- | --- |
| Zona direta | `corp.lab.internal` (integrada ao AD) | Replicação segura junto com o AD |
| Zona reversa | `0.50.10.in-addr.arpa` | PTR para troubleshooting (`nslookup` por IP) e logs legíveis |
| Atualização dinâmica | Somente segura | Só computadores do domínio registram nomes |
| Encaminhadores | `1.1.1.1`, `8.8.8.8` | Resolução de nomes externos |
| Aging/Scavenging | 7 + 7 dias | Remove registros antigos deixados por clientes DHCP |
| Registros fixos | A + PTR de DC01, FS01, MON01 | Servidores com IP estático |

## DHCP

| Configuração | Valor |
| --- | --- |
| Escopo | `LAB-Estacoes` · `10.50.0.100–200` · lease de 8 h |
| Opções | Gateway `10.50.0.1`, DNS `10.50.0.10`, domínio `corp.lab.internal` |
| Integração com DNS | O DHCP registra e remove os registros A dos clientes |
| Autorização | Servidor autorizado no AD (evita servidor DHCP "pirata") |

**Validação antes de aplicar:** o script recusa um escopo fora da sub-rede ou sobreposto a um IP fixo de servidor, usando as funções de cálculo IPv4 do módulo `InfraLab`, que têm testes unitários.

## Como executar

```powershell
.\Set-LabDns.ps1 -WhatIf
.\Set-LabDns.ps1
.\Set-LabDhcp.ps1
```

## Validação

- [ ] `nslookup fs01` e `nslookup 10.50.0.20` respondem pelo DC01
- [ ] CL01 recebe IP no intervalo `.100–.200` com DNS `10.50.0.10` (`ipconfig /all`)
- [ ] Registro A do CL01 aparece na zona após o lease
