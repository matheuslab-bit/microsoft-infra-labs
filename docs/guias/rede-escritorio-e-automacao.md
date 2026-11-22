# Rede do escritório e rede de automação (TI e OT)

Empresa com operação física (fábrica, centro de distribuição, laboratório) tem duas redes com prioridades opostas. Tratar as duas do mesmo jeito é a receita para um incidente.

| | TI (escritório) | OT (automação) |
| --- | --- | --- |
| O que tem | Estações, e-mail, ERP, arquivos | CLPs, supervisórios (SCADA), máquinas com computador embarcado, equipamentos de laboratório |
| Prioridade | Confidencialidade: proteger o dado | Disponibilidade: a máquina não pode parar |
| Atualização | Sempre, o quanto antes | Só com o fabricante e com a máquina parada. Às vezes nunca (Windows antigo que o fabricante não suporta atualizar) |
| Janela de manutenção | Fora do horário comercial | Na parada programada da operação |

## Como separar

O modelo de referência é o **Purdue**, usado pela norma **ISA/IEC 62443**. Ele divide a rede em níveis, do chão de fábrica até a internet:

```text
Internet
   │
Rede corporativa (TI)          e-mail, ERP, estações
   │
DMZ industrial                 servidor de histórico, servidor de atualização, salto para acesso remoto
   │
Rede de supervisão (OT)        SCADA, estações de operação
   │
Rede de controle               CLPs, máquinas
```

Regras práticas:

- **Cada nível na sua VLAN e zona de firewall**, só com as regras que precisam passar. No [lab 08](../../labs/08-fortigate-segmentation/README.md) separo servidores, estações e gerência no FortiGate. Uma operação física acrescenta as VLANs de automação e de laboratório.
- **A rede de automação não fala com a internet.** O que ela precisa (atualização de antivírus, envio de dados para o ERP) passa por um servidor na DMZ.
- **Nenhuma conexão direta da TI para a OT.** Tudo passa pela DMZ.
- **Equipamento que não pode ser atualizado fica isolado**, em vez de ser atualizado às pressas e parar a linha.

## Acesso remoto de fornecedor

O fabricante da máquina vai pedir acesso remoto. O jeito seguro:

- Entrada única, por VPN, até um servidor de salto na DMZ, com conta nominal para cada técnico.
- Acesso liberado só durante o atendimento e desligado depois.
- Sessão registrada: quem entrou, quando e o que fez.
- Nunca um software de acesso remoto instalado na máquina com saída livre para a internet.

## Monitoramento sem atrapalhar

- Monitorar switches, firewall e servidores da OT pelo Zabbix ([lab 07](../../labs/07-monitoring-zabbix/README.md)), mas sem varreduras agressivas: alguns CLPs travam com um scan de portas.
- Inventário dos equipamentos da OT, com fabricante, versão, IP, dono e contato do suporte.
- Backup da configuração dos CLPs e dos supervisórios, combinado com a engenharia ou a manutenção, que são os donos desses equipamentos.

## Quem é dono do quê

Na OT, a TI raramente é a dona do equipamento. A máquina é da produção ou da manutenção, e quem configura o CLP é a engenharia ou o fabricante. A TI cuida da rede, do acesso e do monitoramento, e toda mudança é combinada com quem opera a máquina.
