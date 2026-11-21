# Automação com JavaScript

No trabalho eu uso JavaScript para tirar da frente tarefas repetitivas da equipe. Aqui ficam três automações nesse estilo, pensadas para quem cuida de infraestrutura. Rodam com Node.js 20 ou mais novo e não precisam instalar nenhuma dependência.

## Os scripts

**`relatorio-chamados.js`**: lê a exportação de chamados em CSV (do Movidesk, do GLPI ou de qualquer ferramenta que exporte CSV) e monta um relatório em Markdown com o total de chamados, o percentual dentro do SLA e o tempo médio de resolução, separados por categoria e por prioridade. É o relatório da reunião semanal sem precisar montar planilha.

```bash
node src/relatorio-chamados.js dados/chamados-exemplo.csv --saida relatorio.md
```

Com o arquivo de exemplo, o resultado começa assim:

```text
- Chamados no período: 16 (14 fechados, 2 em aberto)
- Fechados dentro do SLA: 78.6%
- Tempo médio de resolução: 3.6 h
```

**`verificar-certificados.js`**: conecta em cada site ou servidor, lê o certificado TLS e mostra quantos dias faltam para vencer. Certificado vencido derruba sistema e costuma ser descoberto pelo usuário. O script sai com código 1 se algum estiver perto de vencer, então dá para agendar e receber o alerta.

```bash
node src/verificar-certificados.js intranet.empresa.com.br mail.empresa.com.br:443 --limite 30
```

**`monitor-servicos.js`**: verifica uma lista de serviços web (código HTTP e tempo de resposta) definida num arquivo JSON. Mostra uma tabela, ou com `--json` gera uma saída que o Zabbix ou o Grafana conseguem ler.

```bash
node src/monitor-servicos.js dados/servicos-exemplo.json
node src/monitor-servicos.js dados/servicos-exemplo.json --json
```

## Testes

As partes de cálculo (leitura do CSV, SLA, dias até o vencimento, classificação de status) têm testes com o test runner nativo do Node, e rodam no CI a cada push:

```bash
npm test
```

## Como agendar

No Windows, pelo Agendador de Tarefas, chamando `node.exe` com o caminho do script. No Linux, com o cron:

```bash
# todo dia às 7h, verifica os certificados e grava o resultado
0 7 * * * cd /opt/automacao-js && node src/verificar-certificados.js intranet.empresa.com.br >> /var/log/certificados.log 2>&1
```
