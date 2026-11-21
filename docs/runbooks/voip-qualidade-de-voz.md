# VoIP: voz ruim, chamada muda ou caindo

Este é o tipo de chamado que mais atendo no dia a dia. A regra é separar **sinalização** (SIP: a chamada completa ou não) de **mídia** (RTP: o áudio chega bem ou não).

## Valores de referência

| Métrica | Bom | Já incomoda |
| --- | --- | --- |
| Latência (só ida) | até 150 ms | acima de 300 ms (as pessoas falam ao mesmo tempo) |
| Jitter | até 30 ms | acima de 50 ms (voz picotada) |
| Perda de pacotes | até 1% | acima de 3% (palavras somem) |
| MOS | 4,0 ou mais | abaixo de 3,5 |

Banda por chamada: G.711 usa cerca de 87 kbps com cabeçalhos, G.729 cerca de 31 kbps. Um link congestionado derruba a qualidade de todas as chamadas.

## Sintoma e causa provável

| Sintoma | Causa mais comum | Onde olhar |
| --- | --- | --- |
| Áudio só de um lado | NAT: o SDP anuncia IP privado, ou a porta RTP está bloqueada no firewall | IP no campo `c=` do SDP; regras de RTP; SIP ALG do roteador (desligar) |
| Voz picotada ou robotizada | Jitter e perda: link saturado ou Wi-Fi ruim | Uso do link, QoS (DSCP EF para voz), testar no cabo |
| Chamada cai em ~30 segundos | O ACK não chega: problema de NAT ou de roteamento na resposta | Trace SIP: INVITE e 200 OK sem ACK |
| Chamada cai em minutos fixos | Session timer ou timeout de UDP no firewall | `Session-Expires`; timeout de UDP no firewall |
| Eco | Atraso alto ou aparelho/headset com problema | Latência, cancelamento de eco, trocar o headset |
| Ramal não registra | Senha, IP ou porta errados, ou firewall | Respostas 401/403 no REGISTER |

## Códigos SIP que mais aparecem

| Código | Significado | Primeiro passo |
| --- | --- | --- |
| 401 / 407 | Pede autenticação | Normal no primeiro REGISTER. Se repetir, senha errada |
| 403 | Proibido | Usuário sem permissão ou IP não autorizado na operadora |
| 404 | Número não encontrado | Plano de discagem ou número digitado errado |
| 408 | Tempo esgotado | Destino não responde: rede, firewall ou aparelho desligado |
| 480 | Indisponível | Ramal não registrado ou em "não perturbe" |
| 486 | Ocupado | Normal |
| 488 | Mídia não aceita | Os dois lados não têm codec em comum |
| 503 | Serviço indisponível | Tronco ou operadora fora, limite de canais atingido |

## Como capturar

```bash
# no servidor Linux (Asterisk, FreeSWITCH, SBC)
sngrep                                   # fluxo SIP em tempo real, por chamada
tcpdump -i any -w chamada.pcap port 5060 or portrange 10000-20000
```

No Wireshark: menu Telefonia > Chamadas VoIP mostra o fluxo e permite ouvir o áudio. Telefonia > RTP > Fluxos RTP mostra jitter e perda de cada lado.

## Registrar no chamado

Número de origem e destino, horário exato, Call-ID da chamada, código SIP de erro e os valores de jitter e perda. Com isso a operadora consegue investigar do lado dela.
