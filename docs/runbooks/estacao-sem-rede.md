# Estação sem rede ou sem internet

Investigar de baixo para cima: cabo, IP, gateway, DNS, internet, porta do sistema. O [`diagnostico-rede.bat`](../../toolkit/windows/diagnostico-rede.bat) faz esse roteiro sozinho e mostra onde parou.

## 1. Tem IP?

```cmd
ipconfig /all
```

| O que aparece | Significado |
| --- | --- |
| Mídia desconectada | Cabo, porta do switch ou Wi-Fi desligado |
| IP 169.254.x.x | O DHCP não respondeu: escopo cheio, VLAN errada ou servidor DHCP parado |
| IP de outra faixa | Máquina na VLAN errada ou IP fixo antigo configurado |
| IP certo | Seguir para o passo 2 |

## 2. Fala com o gateway?

```cmd
ping <gateway>
```

Se falhar: problema na rede local (switch, porta, VLAN). Em outras máquinas do mesmo setor também falha? Então é o switch ou o uplink, não a estação.

## 3. O DNS resolve?

```cmd
nslookup intranet.empresa.local
nslookup www.google.com 1.1.1.1
```

Se resolve pelo 1.1.1.1 e não pelo DNS interno, o problema é o servidor DNS. Numa estação do domínio, o DNS precisa ser o DC, nunca o roteador.

## 4. Sai para a internet?

```cmd
ping 1.1.1.1
tracert -d 1.1.1.1
```

Para no primeiro salto: firewall ou rota. Passa da rede local e para depois: link da operadora.

## 5. É só um sistema?

```powershell
Test-NetConnection erp.empresa.local -Port 443
```

Porta fechada com o resto funcionando: regra de firewall, serviço parado no servidor ou proxy.

## Antes de escalar

Rodar o [`reparo-rede.bat`](../../toolkit/windows/reparo-rede.bat) (limpa o DNS e renova o IP) e anexar ao chamado a saída do diagnóstico.
