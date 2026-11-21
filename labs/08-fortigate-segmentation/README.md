# Lab 08 - FortiGate e VLANs

Nos labs anteriores a rede é plana: tudo na mesma faixa. Numa empresa isso é arriscado, porque um vírus numa estação enxerga todos os servidores. Neste lab separo a rede em VLANs e uso um FortiGate para controlar o que pode falar com o quê.

## Desenho

```text
Internet
   │
port1 (WAN)
FortiGate-VM
port2 (trunk 802.1Q)
   ├── VLAN 10  Servidores  10.50.10.0/24  (DC01, FS01)
   ├── VLAN 20  Estações    10.50.20.0/24  (DHCP via relay para o DC01)
   └── VLAN 99  Gerência    10.50.99.0/24  (único lugar de onde se administra o firewall)
```

## Regras entre as redes

| # | De → Para | Liberado | Por quê |
| --- | --- | --- | --- |
| 10 | Estações → DC01 | DNS, Kerberos, LDAP, NTP, SMB, RPC | O mínimo para logon e GPO funcionarem |
| 20 | Estações → FS01 | SMB (445) | Acesso às pastas |
| 30 | Estações → Internet | HTTP, HTTPS, DNS | Com NAT, filtro web e antivírus |
| 40 | Servidores → Internet | HTTP, HTTPS, DNS, NTP | Atualizações |
| 50 | Gerência → todas | Tudo | Administração |
| - | Qualquer outra coisa | Bloqueado | E registrado no log |

Estação não fala com estação, e estação não acessa a gerência dos servidores nem do firewall. Se uma máquina for comprometida, o estrago fica contido na VLAN dela.

## Outros cuidados na configuração

- O acesso administrativo ao FortiGate só é aceito a partir da VLAN 99 (`trusthost`), em porta HTTPS alternativa, com bloqueio depois de 3 senhas erradas.
- Um único servidor DHCP (o DC01) atende as estações de outra VLAN através do DHCP relay do FortiGate.
- Tudo é registrado em log, inclusive o tráfego bloqueado pela regra implícita. Isso ajuda muito na hora do troubleshooting ("é o firewall ou não é?").
- Os objetos seguem um padrão de nome: `net-` para redes, `host-` para máquinas e `grp-` para grupos de serviço.

## Como usar

1. Importar a FortiGate-VM no Hyper-V. A Fortinet oferece uma licença de avaliação permanente no portal deles.
2. Colar o [`fortigate-baseline.conf`](fortigate-baseline.conf) na CLI, por partes.
3. Colocar cada VM na VLAN certa, por exemplo: `Set-VMNetworkAdapterVlan -VMName CL01 -Access -VlanId 20`.

## Checklist

- [ ] O CL01, na VLAN 20, pega IP pelo relay e faz logon no domínio
- [ ] O CL01 não consegue abrir a página de administração do FortiGate
- [ ] O log mostra o tráfego bloqueado entre as VLANs
