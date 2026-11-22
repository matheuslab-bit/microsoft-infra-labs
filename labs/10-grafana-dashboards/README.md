# Lab 10 - Dashboards no Grafana

> **Em poucas palavras:** O Grafana é o painel do carro: junta os números do Zabbix numa tela só, fácil de ler de longe.

**Situação:** scripts prontos e testados no CI. A execução no meu Hyper-V está em andamento, e o checklist no fim desta página mostra o que já foi conferido.

No trabalho eu acompanho os serviços e os indicadores de SLA em dashboards no Grafana. Aqui monto o mesmo esquema para o lab: o Grafana lê os dados do Zabbix (Lab 07) e mostra tudo numa tela só, que dá para deixar aberta numa TV da equipe.

## Como está montado

```text
MON01 (Docker)
 ├── Zabbix (Lab 07)  ── coleta dos agentes no DC01 e no FS01
 └── Grafana :3000    ── lê o Zabbix pela API (plugin Zabbix) e mostra os painéis
```

Tudo sobe configurado, sem clicar em nada:

- o plugin do Zabbix é instalado e habilitado ([`provisioning/plugins`](provisioning/plugins/zabbix.yml));
- a fonte de dados aponta para a API do Zabbix ([`provisioning/datasources`](provisioning/datasources/zabbix.yml)), com usuário e senha vindos do `.env`;
- o painel [`infra-visao-geral.json`](dashboards/infra-visao-geral.json) é carregado na pasta "Infraestrutura".

## O painel "Infraestrutura - visão geral"

Linha de cima, com indicadores que ficam verdes, amarelos ou vermelhos:

- falhas de replicação do AD (o certo é 0);
- contas bloqueadas (um pico pode ser tentativa de adivinhar senhas);
- idade do último backup (passou de 1 dia, a rotina falhou);
- serviços críticos parados (NTDS, DNS, Netlogon, KDC, DHCP).

Embaixo: CPU e memória por servidor ao longo do dia, disco usado por volume (amarelo a partir de 80%, vermelho a partir de 90%) e a lista de problemas ativos no Zabbix.

Os três primeiros indicadores usam os itens do template [`template-lab-windows-ad.yaml`](../07-monitoring-zabbix/template-lab-windows-ad.yaml), que fica no Lab 07 e já vem com os gatilhos de alerta. Os outros usam o template padrão "Windows by Zabbix agent".

## Como rodar

1. Suba o Zabbix do Lab 07.
2. No Zabbix, importe o template (Data collection > Templates > Import) e vincule aos servidores.
3. Crie um usuário só de leitura para o Grafana (por exemplo, `grafana`).
4. Suba o Grafana:

```bash
cd labs/10-grafana-dashboards
cp .env.example .env     # coloque a senha do admin e a do usuário grafana
docker compose up -d     # http://10.50.0.30:3000
```

## Por que fiz assim

- **Grafana e Zabbix separados:** o Zabbix coleta e alerta; o Grafana só mostra. Se o Grafana cair, o monitoramento continua.
- **Usuário só de leitura no Zabbix:** o Grafana não precisa de permissão para alterar nada.
- **Configuração como arquivo:** a fonte de dados e o painel ficam no Git. Recriar o Grafana do zero leva um comando.
- **Versão fixa da imagem** (`grafana-oss:11.3.0`), para não mudar sozinha numa atualização.

## Checklist

- [ ] O Grafana abre em `http://10.50.0.30:3000` com a fonte de dados Zabbix funcionando (Test = OK)
- [ ] O painel mostra CPU e memória do DC01 e do FS01
- [ ] Parar o serviço DNS no DC01 deixa o indicador "Serviços críticos parados" vermelho
