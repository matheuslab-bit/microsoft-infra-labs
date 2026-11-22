# Checklist: TI de uma filial nova

Para quando a empresa abre uma unidade em outra cidade, como uma fábrica, um centro de distribuição ou um escritório, ligada à matriz. A TI precisa estar pronta **antes** da operação começar, e boa parte do trabalho depende da obra. Por isso o checklist começa nela.

## Durante a obra

- [ ] Sala de TI definida, com climatização dedicada, controle de acesso físico e longe de água
- [ ] Nobreak dimensionado para o rack, ligado ao gerador (se houver), com aterramento conferido
- [ ] Cabeamento estruturado **certificado** (relatório do instalador guardado), com pontos de rede previstos também na operação, na portaria e no almoxarifado
- [ ] Estudo de cobertura do Wi-Fi feito com o prédio pronto (galpões e estruturas metálicas mudam tudo)
- [ ] Dois links de internet de **operadoras diferentes**, chegando por caminhos diferentes
- [ ] Prazo de ativação dos links acompanhado: costuma ser o item que mais atrasa

## Rede

- [ ] Plano de IP documentado, sem sobrepor as faixas da matriz
- [ ] Firewall (FortiGate) com VPN site-to-site ou SD-WAN até a matriz, e failover entre os dois links testado
- [ ] VLANs separadas, como no [lab 08](../../labs/08-fortigate-segmentation/README.md):
  - servidores;
  - estações;
  - gerência;
  - automação (OT), se houver;
  - CFTV e controle de acesso;
  - voz;
  - visitantes.
- [ ] Regras entre as VLANs só com o necessário. A rede de automação não fala com a internet ([guia de TI e OT](../guias/rede-escritorio-e-automacao.md))
- [ ] Switches gerenciáveis com configuração salva e backup da configuração
- [ ] Acesso remoto de fornecedores definido: por onde entra, quem libera, onde fica registrado

## Identidade e serviços

- [ ] Site novo e sub-redes cadastrados no AD Sites and Services, para as estações autenticarem no DC mais próximo
- [ ] Decisão registrada: controlador de domínio local ou só o da matriz (depende da qualidade e da redundância do link)
- [ ] DNS e DHCP da unidade ([lab 03](../../labs/03-dns-dhcp/README.md)) e OU da unidade com as GPOs ([lab 04](../../labs/04-group-policy/README.md))
- [ ] Horário sincronizado em tudo (servidores, estações, câmeras, relógio de ponto e equipamentos), a partir da mesma fonte de NTP
- [ ] Impressoras, incluindo as de etiqueta da expedição
- [ ] Telefonia: ramais VoIP na VLAN de voz com QoS, testados com chamada real ([runbook de qualidade de voz](../runbooks/voip-qualidade-de-voz.md))
- [ ] Acesso ao ERP e aos sistemas da matriz testado a partir da unidade, com o tempo de resposta medido

## Sistemas críticos

- [ ] Inventário dos sistemas da unidade, com dono e criticidade de cada um
- [ ] Servidores críticos com a instalação documentada antes do uso ([guia de rastreabilidade](../guias/rastreabilidade-e-auditoria.md#servidor-documentado-desde-a-instalação))
- [ ] Procedimentos escritos (backup, acesso, mudanças, incidentes) aprovados e com treinamento registrado
- [ ] Equipamentos que não podem ser atualizados isolados na rede

## Backup e monitoramento

- [ ] Backup local com cópia na matriz ou na nuvem (regra 3-2-1) e **uma restauração testada** ([lab 06](../../labs/06-backup-recovery/README.md))
- [ ] Zabbix monitorando links, firewall, switches, nobreak e servidores, com um proxy na unidade para não perder dados se o link cair ([lab 07](../../labs/07-monitoring-zabbix/README.md))
- [ ] Painel da unidade no Grafana ([lab 10](../../labs/10-grafana-dashboards/README.md))
- [ ] Alertas chegando para a equipe certa, inclusive fora do horário comercial

## Antes de começar a operar

- [ ] Simulado de queda do link principal: o secundário assume e os sistemas continuam respondendo
- [ ] Simulado de queda de energia: o nobreak segura até o gerador entrar
- [ ] Documentação "como construído" (as-built): diagrama de rede, plano de IP, rack, senhas no cofre e contatos dos fornecedores
- [ ] Cada servidor passou pelo [checklist de servidor novo](servidor-novo.md)
- [ ] Aceite formal das áreas que vão usar a unidade
