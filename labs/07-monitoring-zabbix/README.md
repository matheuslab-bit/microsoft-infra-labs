# Lab 07 - Monitoramento com Zabbix

Na Desktop eu acompanhava a rede dos clientes pelo Zabbix e pelo PRTG, e o que mais fazia diferença era ver o problema antes de o cliente ligar. Aqui monto o Zabbix para o lab e crio alguns itens que não vêm prontos, focados em AD e backup.

## Como está montado

```text
MON01 (Ubuntu 24.04 + Docker)
 ├── zabbix-web     porta 8080 (painel)
 ├── zabbix-server  porta 10051
 └── PostgreSQL 16  (dados em volume, não se perdem ao recriar os contêineres)

DC01 e FS01: Zabbix Agent 2
```

Uso o Zabbix 7.0 por ser versão LTS, com suporte longo.

## O que é monitorado

Já vem pronto no template do Windows:
- CPU, memória e disco (alerta com menos de 15% livre)
- Serviços importantes parados: NTDS, DNS, Netlogon, KDC e DHCP
- Eventos do Windows, como o 4740 (conta bloqueada)

Itens que eu criei ([`agent2.d/windows-ad.conf`](agent2.d/windows-ad.conf)):
- `ad.replication.failures`: quantos parceiros de replicação do AD estão com falha (o certo é 0)
- `ad.users.locked`: quantas contas estão bloqueadas. Um pico fora do normal pode indicar alguém tentando adivinhar senhas
- `lab.backup.age.days`: há quantos dias foi feito o último backup. Se passar de 1, algo deu errado na rotina

## Como rodar

No MON01:

```bash
cd labs/07-monitoring-zabbix
cp .env.example .env    # trocar a senha no .env
docker compose up -d    # painel em http://10.50.0.30:8080
```

Em cada servidor Windows (o MSI do Agent 2 é baixado no site do Zabbix):

```powershell
.\Install-LabZabbixAgent.ps1 -MsiPath C:\Temp\zabbix_agent2-7.0-windows-amd64-openssl.msi
```

O script instala o agente, copia os itens personalizados e libera a porta 10050 no firewall só para o IP do MON01.

Para não criar os itens à mão, importe o template [`template-lab-windows-ad.yaml`](template-lab-windows-ad.yaml) (Data collection > Templates > Import). Ele já traz os três itens personalizados com os gatilhos de alerta: replicação com falha, 10 ou mais contas bloqueadas e backup com mais de 1 dia. Os painéis do Grafana no [Lab 10](../10-grafana-dashboards/README.md) usam esses mesmos itens.

No painel do Zabbix, configuro uma ação de autorregistro (Alerts > Actions > Autoregistration) com a condição "Host metadata contém windows-lab". Assim, todo servidor novo com o agente entra no monitoramento sozinho, já com o template certo.

## Cuidados

- O `.env` tem a senha do banco e não vai para o Git. No repositório fica só o `.env.example`.
- Se o host aparecer vermelho (ZBX), quase sempre é firewall ou o `Server=` errado no arquivo do agente.

## Checklist

- [ ] DC01 e FS01 aparecem verdes no Zabbix
- [ ] `zabbix_get -s 10.50.0.10 -k ad.replication.failures` retorna `0`
- [ ] Parar o serviço DNS no DC01 gera alerta em até 1 minuto
